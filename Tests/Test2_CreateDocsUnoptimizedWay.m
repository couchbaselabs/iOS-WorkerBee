//
//  PerfTestScenario3.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/7/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import <malloc/malloc.h>
#import "Test2_CreateDocsUnoptimizedWay.h"
#import <CouchbaseLite/CBLJSON.h>

#define kNumberOfDocuments 10

// Multiplier for generating an array with
// 'kSizeOfDocument' indexes
#define kSizeofDocument 50

@implementation Test2_CreateDocsUnoptimizedWay

- (void) heartbeat {
    [self logFormat: @"Starting Test"];
    
    
    
    NSString *value = @"1234567";
    
    NSMutableArray *bigObj = [[NSMutableArray alloc] init];
    for (int i = 0; i < kSizeofDocument; i++) {
        [bigObj addObject:value];
    }
    
    NSDictionary* props = @{@"bigArray": bigObj};
    
    NSDate *start = [NSDate date];
    
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
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time Taken: %f",executionTime];
    self.running = NO;
    
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}

@end