//
//  PerfTestScenario7.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/13/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import <malloc/malloc.h>
#import "Test7_PullReplication.h"
#import <CouchbaseLite/CouchbaseLite.h>


#define kNumberOfDocuments 10000
// size in bytes
#define kSizeofDocument 100000

@implementation Test7_PullReplication


- (void) replicationChanged: (NSNotificationCenter*)n {
    
    if (self.pull) {
        [self logFormat: @"Change in status"];
        
        unsigned completed = self.pull.completedChangesCount;
        unsigned total = self.pull.changesCount;
        
        [self logFormat: @"Completed %d Out of total %d",completed,total];
        
        if (self.pull.status == kCBLReplicationStopped && !self.pull.lastError) {
            [self logFormat: @"Replication Stopped and No Error Found"];
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:self.startTime];
            [self logFormat:@"Total Time Taken: %f",executionTime];
            [self logFormat: @"Completed %d Out of total %d",completed,total];
        }
        
        if (self.pull.status == kCBLReplicationStopped) {
            [self logFormat: @"Replication Stopped"];
            self.running = NO;
        }
    }
}

- (void) setUp {
    [super setUp];
    
    NSURL *syncGateway  = [NSURL URLWithString:@"http://10.17.24.121:4985/sync_gateway"];
    
    self.pull = [self.database replicationFromURL: syncGateway];
    self.pull.persistent = NO;

    // Start measuring time from here
    self.startTime = [NSDate date];
    
    [self logFormat: @"Start Replication: Pull"];
    [self.pull start];
    
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver: self selector: @selector(replicationChanged:)
                 name: kCBLReplicationChangeNotification object: self.pull];
}

@end
