//
//  PerfTestScenario1.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 1/31/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import <malloc/malloc.h>
#import "Test1_CreateDocs.h"
#import <CouchbaseLite/CBLJSON.h>

@implementation Test1_CreateDocs

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        NSMutableString *str = [NSMutableString stringWithCapacity:kSizeofDocument];
        for (int i = 0; i< kSizeofDocument; i++) {
            [str appendString:@"1"];
        }
        NSDictionary* props = @{@"data": str};

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
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        return executionTime;
    }
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}

@end
