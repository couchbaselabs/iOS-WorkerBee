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

#define kNumberOfDocuments 25000
// size in bytes
#define kSizeofDocument 10000


@implementation Test6_PushReplication
{
    NSDate* _pushStartTime;
}

- (void) replicationChanged: (NSNotificationCenter*)n {
    
    
   [self logFormat: @"Change in status"];
   
   unsigned completed = self.push.completedChangesCount;
   unsigned total = self.push.changesCount;
   
   [self logFormat: @"Completed %d Out of total %d",completed,total];
   
   if (self.push.status == kCBLReplicationStopped && !self.push.lastError) {
       [self logFormat: @"Replication Stopped and No Error Found"];
       NSDate *methodFinish = [NSDate date];
       NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:_pushStartTime];
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
    
    NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
    memset(utf8.mutableBytes, '1', utf8.length);
    NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
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

    
    NSURL *syncGateway  = [NSURL URLWithString:@"http://localhost:4984/db"];
    
    self.push = [self.database createPushReplication: syncGateway];
    [self logFormat: @"Start Replication: Push"];

    // Start measuring time from here
    _pushStartTime = [NSDate date];
    
    [self.push start];

    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver: self selector: @selector(replicationChanged:)
                 name: kCBLReplicationChangeNotification object: self.push];
    
}


@end
