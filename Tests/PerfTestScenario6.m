//
//  PerfTestScenario6.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/12/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import <malloc/malloc.h>
#import "PerfTestScenario6.h"
#import <CouchbaseLite/CouchbaseLite.h>

#define kNumberOfDocuments 1
// size in bytes
#define kSizeofDocument 10


@implementation PerfTestScenario6

- (void) heartbeat {
    
    [self logFormat: @"heartbeat"];

}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    
    if (self.push) {
        [self logFormat: @"Change in status"];
        if (self.push.status == kCBLReplicationStopped && !self.push.lastError) {
            [self logFormat: @"Replication Stopped and No Error Found"];
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:self.startTime];
            [self logFormat:@"Total Time Taken: %f",executionTime];
        }
        
        if (self.push.status == kCBLReplicationStopped) {
            [self logFormat: @"Replication Stopped"];
            self.running = NO;
        }
    }
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
    
    NSMutableString *str = [[NSMutableString alloc] init];
    
    for (int i = 0; i < kSizeofDocument; i++) {
        [str appendString:@"1"];
    }
    
    NSDictionary* props = @{@"k": str};
    
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
    
    NSURL *syncGateway  = [NSURL URLWithString:@"http://10.17.23.126:4985/sync_gateway"];
    
    self.push = [self.database replicationToURL: syncGateway];
    self.push.persistent = NO;
    
    // Start measuring time from here
    self.startTime = [NSDate date];
    
    [self logFormat: @"Start Replication: Push"];
    [self.push start];
    
    [self.push addObserver: self
                forKeyPath: @"status"
                   options: 0
                   context: NULL];
    
}


@end
