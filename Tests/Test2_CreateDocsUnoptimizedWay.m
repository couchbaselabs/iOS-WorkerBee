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

@implementation Test2_CreateDocsUnoptimizedWay

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
        NSDictionary* props = @{@"k": str};

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
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        return executionTime;
    }
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}

@end