//
//  PerfTestScenario6.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/12/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import <malloc/malloc.h>
#import "Test6_PushReplication.h"
#import <CouchbaseLite/CouchbaseLite.h>

#define kNumberOfDocuments 100
// size in bytes
#define kSizeofDocument 100000


@implementation Test6_PushReplication

- (void) replicationChanged: (NSNotificationCenter*)n {
    
    
   [self logFormat: @"Change in status"];
   
   unsigned completed = self.push.completedChangesCount;
   unsigned total = self.push.changesCount;
   
   [self logFormat: @"Completed %d Out of total %d",completed,total];
   
   if (self.push.status == kCBLReplicationStopped && !self.push.lastError) {
       [self logFormat: @"Replication Stopped and No Error Found"];
       NSDate *methodFinish = [NSDate date];
       NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:self.startTime];
       [self logFormat:@"Total Time Taken: %f",executionTime];
       [self logFormat: @"Completed %d Out of total %d",completed,total];
   }
   
   if (self.push.status == kCBLReplicationStopped) {
       [self logFormat: @"Replication Stopped"];
       self.running = NO;
   }
    
}


- (void) setUp {
    [super setUp];
    
    NSMutableString *str = [[NSMutableString alloc] init];
    
    for (int i = 0; i < kSizeofDocument; i++) {
        [str appendString:@"1"];
    }
    
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

    
    NSURL *syncGateway  = [NSURL URLWithString:@"http://10.0.1.10:4985/sync_gateway"];
    
    self.push = [self.database replicationToURL: syncGateway];
    self.push.persistent = NO;
    
    // Start measuring time from here
    self.startTime = [NSDate date];
    
    [self logFormat: @"Start Replication: Push"];
    [self.push start];

    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver: self selector: @selector(replicationChanged:)
                 name: kCBLReplicationChangeNotification object: self.push];
    
}


@end
