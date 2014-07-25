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

@implementation Test6_PushReplication
{
    NSDate* start;
    NSString *syncGatewayUrl;
    int kNumberOfDocuments;
    int kSizeofDocument;
    double kpiTotalTime;
}

- (void) replicationChanged: (NSNotificationCenter*)n {
    
    
   [self logFormat: @"Change in status"];
   
   unsigned completed = self.push.completedChangesCount;
   unsigned total = self.push.changesCount;
   
   [self logFormat: @"Completed %d Out of total %d",completed,total];
   
   if (self.push.status == kCBLReplicationStopped && !self.push.lastError) {
       [self logFormat: @"Replication Stopped and No Error Found"];
       NSDate *methodFinish = [NSDate date];
       NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
       [self logFormat:@"Total Time Taken: %f",executionTime];
       [self logFormat: @"Completed %d Out of total %d",completed,total];
   }
   
   if (self.push.status == kCBLReplicationStopped) {
       [self logFormat: @"Replication Stopped"];
       NSDate *methodFinish = [NSDate date];
       NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
       [self logFormat:@"Test %@: Time to push replicate %d documents with size %dB, total latency %.2f: %.2f",[self class], kNumberOfDocuments, kSizeofDocument, executionTime, executionTime/kNumberOfDocuments];
       self.running = NO;
   }
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
    
    NSDictionary* testCaseConfig = [[BeeTest config] objectForKey:NSStringFromClass([self class])];
    kNumberOfDocuments = [[testCaseConfig objectForKey:@"number_of_documents"] intValue];
    kSizeofDocument = [[testCaseConfig  objectForKey:@"size_of_document"] intValue];
    syncGatewayUrl = [testCaseConfig  objectForKey:@"sync_gateway_url"];
    
    [self logFormat: @"Starting Test %@ - numberOfDocuments %d, sizeofAttachment %d, to Sync_gateway %@",[self class], kNumberOfDocuments, kSizeofDocument,syncGatewayUrl];
    
    @autoreleasepool {
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
    }
    
    @autoreleasepool {
        NSURL *syncGateway  = [NSURL URLWithString:syncGatewayUrl];
        self.push = [self.database createPushReplication: syncGateway];
        [self logFormat: @"Starting Push Replication"];
        
        // Start measuring time from here
        start = [NSDate date];
        
        [self.push start];
        
        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        [nctr addObserver: self selector: @selector(replicationChanged:)
                     name: kCBLReplicationChangeNotification object: self.push];
    }
}

@end
