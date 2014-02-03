//
//  PerfTestScenario1.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 1/31/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import <malloc/malloc.h>
#import "PerfTestScenario1.h"
#import <CouchbaseLite/CBLJSON.h>


#define kDocumentBatchSize 100

#define kNumberOfDocuments 100
// Multiplier for generating an array with
// 'kSizeOfDocument' indexes
#define kSizeofDocument 5000000


@implementation PerfTestScenario1
{
    int _sequence;
}

- (void) heartbeat {
    [self logFormat: @"Starting Test"];
    
    NSDate *start = [NSDate date];
    
    NSString *value = @"1234567";
    
    NSMutableArray *bigObj = [NSMutableArray arrayWithObjects:nil];
    
    for (int i = 0; i < kSizeofDocument; i++) {
            [bigObj addObject:value];
    }
    
    NSDictionary* props = @{@"bigArray": bigObj};
    
    [self.database inTransaction:^BOOL{
        for (int j = 0; j < kNumberOfDocuments; j++) {
            CBLDocument* doc = [self.database createDocument];
            NSError* error;
            if (![doc putProperties: props error: &error]) {
                [self logFormat: @"!!! Failed to create doc %@", props];
                self.error = error;
            }
        }
        return YES;
    }];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time Taken: %f",executionTime];
    self.running = NO;
    
}

- (void) setUp {
    [super setUp];
    _sequence = 0;
    self.heartbeatInterval = 1.0;
}

@end
