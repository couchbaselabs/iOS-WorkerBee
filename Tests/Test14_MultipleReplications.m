//
//  Test14_MultipleReplications.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 4/24/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test14_MultipleReplications.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

#define kNumberOfDocuments 20
// size in bytes
#define kSizeofDocument 100
// Update this array to add your Sync Gateways
NSString * const syncGateways[] = { @"http://10.17.32.155:4985/sync_gateway1",
                                    @"http://10.17.32.155:4985/sync_gateway2" };


@implementation Test14_MultipleReplications
{
    NSDate* _startTime;
    NSInteger repl_count;
}


- (void) replicationChanged: (NSNotification*)n {
    CBLReplication* repl = n.object;

    
    [self logFormat: @"Got Notification"];
    
    unsigned completed = repl.completedChangesCount;
    unsigned total = repl.changesCount;
    
    [self logFormat: @"Completed %d Out of total %d",completed,total];
    
    if (repl.status == kCBLReplicationStopped && !repl.lastError) {
        repl_count--;
        [self logFormat: @"Remaing Replications = %d",repl_count];
    }
    
    if (repl.status == kCBLReplicationStopped && repl_count == 0) {

        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:_startTime];
        
        [self logFormat: @"Replication Stopped"];
        [self logFormat: @"Total Time Taken: %f",executionTime];
        [self logFormat: @"Completed %d Out of total %d",completed,total];

        self.running = NO;
    }
    
}

// pair = (push,pull)
- (void) startReplication {
    
    int total_SyncGateways = (sizeof syncGateways) / (sizeof syncGateways[0]);
    
    bool started = 0;
    repl_count = 0;

    // For each gateway open a pair(push,pull) replications
    for (int i=0; i < total_SyncGateways; i++) {
        
        NSURL *sg_url  = [NSURL URLWithString:syncGateways[i]];
    
        CBLReplication* push = [self.database createPushReplication: sg_url];
        CBLReplication* pull = [self.database createPullReplication: sg_url];
        
        repl_count = repl_count + 2;
        
        [self logFormat: @"Start Replication for %@",syncGateways[i]];
        
        if (!started) {
            // Start measuring time from here
            _startTime = [NSDate date];
            started = 1;
        }
        
        [push start];
        [pull start];
        
        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        
        [nctr addObserver: self selector: @selector(replicationChanged:)
                     name: kCBLReplicationChangeNotification object: push];
        
        [nctr addObserver: self selector: @selector(replicationChanged:)
                     name: kCBLReplicationChangeNotification object: pull];

    }
    [self logFormat: @"Total Replications = %d",repl_count];
    
}


- (void) setUp {
    [super setUp];
    
    NSData *data = [NSMutableData dataWithLength:kSizeofDocument];
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSDictionary* props = @{@"k": str};
    
    [self.database inTransaction:^BOOL{
        for (int j = 0; j < kNumberOfDocuments; j++) {
            @autoreleasepool {
                CBLDocument* doc = [self.database createDocument];
                NSError* error;
                if (![doc putProperties: props error: &error]) {
                    [self logFormat: @"!!! Failed to create doc %@", props];
                    self.error = error;
                }
            }
        }
        return YES;
    }];
    [self startReplication];

}


@end
