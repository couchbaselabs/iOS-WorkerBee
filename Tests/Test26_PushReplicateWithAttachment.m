//
//  Test26_PushReplicateWithAttachment.m
//  Worker Bee
//
//  Created by Li Yang on 7/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test26_PushReplicateWithAttachment.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

//To run this test, start sync_gateway and change sync_gateway_ip in config.json

@implementation Test26_PushReplicateWithAttachment
{
    bool replicationRunning;
}

- (void) pushReplicationChanged: (NSNotificationCenter*)n {
    // Uncomment the following line to see the progress of replication
    // [self logFormat: @"Completed %d Out of total %d",self.push.completedChangesCount,self.push.changesCount];
    
    if (self.push.status == kCBLReplicationStopped) {
        // If do not see this line, it means there is no error
        if (self.push.lastError)
        [self logSummary:[NSString stringWithFormat:
                          @"*** Replication Stopped and error found - %@", self.push.lastError]];
        replicationRunning = NO;
    }
}

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofAttachment {
    NSDictionary* environmentConfig = [[BeeTest config] objectForKey:@"environment"];
    NSString* syncGatewayIp = [environmentConfig  objectForKey:@"sync_gateway_ip"];
    NSString* syncGatewayPort = [environmentConfig  objectForKey:@"sync_gateway_port"];
    NSString* syncGatewayDb = [environmentConfig  objectForKey:@"sync_gateway_db"];
    NSString* syncGatewayUrl = [NSString  stringWithFormat:@"http://%@:%@/%@",
                                syncGatewayIp, syncGatewayPort, syncGatewayDb];
    [self logFormat: @"Starting Test %@ - Sync_gateway %@, kNumberOfDocuments %i, kSizeofDocument %i", [self class], syncGatewayUrl, kNumberOfDocuments, kSizeofAttachment];
    
    @autoreleasepool {
        NSString *cachesFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *file = [cachesFolder stringByAppendingPathComponent:@"testfile"];
        NSURL* _fileurl = [NSURL fileURLWithPath:file];
        BOOL success = [[NSFileManager defaultManager] createFileAtPath:file contents:nil attributes:nil];
        [self logFormat: @"Created file at %@", _fileurl];
        if (!success) {
            [self logFormat: @"Failed to create file at %@", file];
            self.running = NO;
        }
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:file];
        
        // Append data to the file in increments of 1% of totalsize of attachment
        int allocation_size = (kSizeofAttachment / 100) ? (kSizeofAttachment / 100) : 1;
        
        for (int total = 0; total < kSizeofAttachment; total = total + allocation_size ) {
            @autoreleasepool {
                //[self logFormat: @"Writing data to the file: Total Count %d, allocation size %d", total,allocation_size];
                NSMutableData *data = [NSMutableData dataWithLength:allocation_size];
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:data];
                data = nil;
            }
        }
        [fileHandle closeFile];
        // Check file size created
        NSFileManager *man = [NSFileManager defaultManager];
        NSDictionary *attrs = [man attributesOfItemAtPath:file error: NULL];
        double result = [attrs fileSize];
        [self logFormat: @"Created file size %f", result];
        
        [self.database inTransaction:^BOOL{
            for (int j = 0; j < kNumberOfDocuments; j++) {
                @autoreleasepool {
                    CBLDocument* doc = [self.database createDocument];
                    CBLUnsavedRevision* rev = doc.newRevision;
                    NSString *key = [NSString stringWithFormat:@"%d",j];
                    [rev setAttachmentNamed:key withContentType:@"image/jpg" contentURL:_fileurl];
                    
                    NSError* error;
                    CBLSavedRevision* saved = [rev save:&error];
                    
                    if (!saved){
                        [self logFormat: @"!!! Failed to attach"];
                        self.error = error;
                    }
                }
            }
            return YES;
        }];

    }
    
    @autoreleasepool {
        NSURL *syncGateway  = [NSURL URLWithString:syncGatewayUrl];
        self.push = [self.database createPushReplication: syncGateway];
        [self logFormat: @"Starting Push Replication"];

        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        [nctr addObserver: self selector: @selector(pushReplicationChanged:)
                     name: kCBLReplicationChangeNotification object: self.push];

        // Start measuring time from here
        NSDate* start = [NSDate date];
        [self.push start];

        replicationRunning = YES;
        while (replicationRunning) {
            [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                     beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
        }
        
        NSDate *methodFinish = [NSDate date];
        [self logFormat: @"Push Replication Stopped"];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;

        [nctr removeObserver:self name:kCBLReplicationChangeNotification object:self.push];
        self.push = nil;

        [self deleteDatabase];

        sleep(20);
        return executionTime;
    }
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}

@end
