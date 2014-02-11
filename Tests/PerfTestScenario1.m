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


//#define kNumberOfDocuments 10
//#define kNumberOfDocuments 100
//#define kNumberOfDocuments 1000
//#define kNumberOfDocuments 10000
#define kNumberOfDocuments 50000
//#define kNumberOfDocuments 100000
// Multiplier for generating an array with
// 'kSizeOfDocument' indexes
//#define kSizeofDocument 50
//#define kSizeofDocument 100
//#define kSizeofDocument 1000
#define kSizeofDocument 10000
//#define kSizeofDocument 100000
//#define kSizeofDocument 1000000
//#define kSizeofDocument 5000000


@implementation PerfTestScenario1

- (void) heartbeat {
    [self logFormat: @"Starting Test"];
    
   
    
    NSString *value = @"1234567";
    
    NSMutableArray *bigObj = [[NSMutableArray alloc] init];
    for (int i = 0; i < kSizeofDocument; i++) {
            [bigObj addObject:value];
    }
    
    NSDictionary* props = @{@"bigArray": bigObj};
    
    NSDate *start = [NSDate date];
    
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
