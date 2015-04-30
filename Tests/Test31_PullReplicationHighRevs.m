//
//  Test31_PullReplicationHighRevs.m
//  Worker Bee
//
//  Created by Pasin Suriyentrakorn on 4/30/15.
//  Copyright (c) 2015 Couchbase, Inc. All rights reserved.
//

#import "Test31_PullReplicationHighRevs.h"

#define kNumLocalRevs 500;
#define kNumRemoteAdditionalRevs 500;

@implementation Test31_PullReplicationHighRevs {
    CBLReplication *_currentReplication;
}

- (void) runReplication: (CBLReplication*)repl {
    [self logFormat: @"Waiting for %@ to finish...", repl];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replChanged:)
                                                 name: kCBLReplicationChangeNotification
                                               object: repl];
    _currentReplication = repl;

    bool started = false, done = false;
    [repl start];
    CFAbsoluteTime lastTime = 0;
    while (!done) {
        if (![[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                      beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]])
            break;
        if (repl.running)
            started = true;
        if (started && (repl.status == kCBLReplicationStopped ||
                        repl.status == kCBLReplicationIdle))
            done = true;

        // Replication runs on a background thread, so the main runloop should not be blocked.
        // Make sure it's spinning in a timely manner:
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (lastTime > 0 && now-lastTime > 0.25)
            NSLog(@"Runloop was blocked for %g sec", now-lastTime);
        lastTime = now;
    }
    [self logFormat: @"...replicator finished. mode=%u, progress %u/%u, error=%@",
        repl.status, repl.completedChangesCount, repl.changesCount, repl.lastError];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: kCBLReplicationChangeNotification
                                                  object: _currentReplication];
    _currentReplication = nil;
}

- (void) replChanged: (NSNotification*)n {
    NSAssert(n.object == _currentReplication, @"Wrong replication given to notification");
    [self logFormat: @"Replication status=%u; completedChangesCount=%u; changesCount=%u",
        _currentReplication.status, _currentReplication.completedChangesCount, _currentReplication.changesCount];
    NSAssert(_currentReplication.completedChangesCount <= _currentReplication.changesCount, @"Invalid change counts");
    if (_currentReplication.status == kCBLReplicationStopped) {
        NSAssert(_currentReplication.completedChangesCount == _currentReplication.changesCount,
                 @"Changed counts and Completed change count are not the same.");
    }
}

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    NSDictionary* environmentConfig = [[BeeTest config] objectForKey:@"environment"];
    NSString* syncGatewayIp = [environmentConfig  objectForKey:@"sync_gateway_ip"];
    NSString* syncGatewayPort = [environmentConfig  objectForKey:@"sync_gateway_port"];
    NSString* syncGatewayDb = [environmentConfig  objectForKey:@"sync_gateway_db"];
    NSString* syncGatewayUrl = [NSString  stringWithFormat:@"http://%@:%@/%@",
                                syncGatewayIp, syncGatewayPort, syncGatewayDb];

    NSURL* remoteDbURL = [NSURL URLWithString: syncGatewayUrl];

    [self logFormat: @"Starting Test %@ - Sync_gateway %@, kNumberOfDocuments %i, kSizeofDocument %i",
     [self class], syncGatewayUrl, kNumberOfDocuments, kSizeofDocument];

    // Create base document properties:
    NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
    memset(utf8.mutableBytes, '1', utf8.length);
    NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
    NSDictionary* props = @{@"k": str};

    NSError *error;

    // Create database for pushing documents:
    CBLDatabase* pushDB = [self createEmptyDatabaseNamed: @"pushdb" error: &error];
    if (!pushDB) {
        self.error = error;
        return -1.0;
    }

    NSMutableArray *docs = [NSMutableArray array];
    int NUM_LOCAL_REVS = kNumLocalRevs;
    for (int j = 0; j < kNumberOfDocuments; j++) {
        CBLDocument* doc = [pushDB createDocument];
        [docs addObject: doc];

        // Create local revisions:
        for (int i = 0; i < NUM_LOCAL_REVS; i++) {
            CBLUnsavedRevision *newRev = [doc newRevision];
            NSMutableDictionary *newProps = [NSMutableDictionary dictionaryWithDictionary:props];
            newProps[@"number"] = @(i);
            newRev.userProperties = newProps;
            NSError *error;
            if(![newRev save: &error]) {
                [self logFormat: @"!!! Failed to create a new revision %@ : %@", newProps, error];
                self.error = error;
                break;
            }
        }
        if (self.error)
            break;
    }

    if (self.error) {
        [self logFormat: @"Preparing local documents had an error: %@", self.error];
        return -1.0;
    }

    // Push documents to the sync gateway:
    CBLReplication* pusher = [pushDB createPushReplication: remoteDbURL];
    [self runReplication:pusher];

    // Create database for pulling documents:
    CBLDatabase* pullDB = [self createEmptyDatabaseNamed: @"pulldb" error: &error];
    if (!pullDB) {
        self.error = error;
        return -1.0;
    }

    // Pull inital docs that were push previously:
    CBLReplication* puller = [pushDB createPullReplication: remoteDbURL];
    [self runReplication: puller];

    // Add additional revisions to pushdb and sync gateway:
    int NUM_REMOTE_ADDITIONAL_REVS = kNumRemoteAdditionalRevs;
    for (CBLDocument *doc in docs) {
        // Create local revisions:
        for (int i = 0; i < NUM_REMOTE_ADDITIONAL_REVS; i++) {
            CBLUnsavedRevision *newRev = [doc newRevision];
            NSMutableDictionary *newProps = [NSMutableDictionary dictionaryWithDictionary:props];
            newProps[@"anothernumber"] = @(i);
            newRev.userProperties = newProps;
            NSError *error;
            if(![newRev save: &error]) {
                [self logFormat: @"!!! Failed to create a new revision %@ : %@", newProps, error];
                self.error = error;
                break;
            }
        }
        if (self.error)
            break;
    }

    if (self.error) {
        [self logFormat: @"Adding more revisions to documents had an error: %@", self.error];
        return -1.0;
    }

    // Pull additional revisions (Measure the time here):
    NSDate* start = [NSDate date];
    puller = [pullDB createPullReplication: remoteDbURL];
    [self runReplication: puller];
    NSDate* finish = [NSDate date];
    NSTimeInterval executionTime = [finish timeIntervalSinceDate:start] * 1000;
    [self logFormat: @"Pull Replication Done in %f msec.", executionTime];

    NSAssert([pushDB deleteDatabase: &error], @"Couldn't delete db: %@", error);
    NSAssert([pullDB deleteDatabase: &error], @"Couldn't delete db: %@", error);

    return executionTime;
}

@end
