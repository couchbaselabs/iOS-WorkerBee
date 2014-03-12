//
//  PerfTestScenario11.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/14/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test11_DeleteDocs.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

#define kNumberOfDocuments 10000
// size in bytes
#define kSizeofDocument 1000
#define kNumberOfDeletes 10

@implementation Test11_DeleteDocs

- (void) heartbeat {
    [self logFormat: @"Starting Test"];
    
    // Start measuring time from here
    NSDate *start = [NSDate date];
    int i = 0;
    //[self.database inTransaction:^BOOL{
        for (CBLDocument *doc in self.docs) {
            @autoreleasepool {
                if (i < kNumberOfDeletes) {
                    // delete document
                    NSError* error;
                    if (![doc deleteDocument: &error]) {
                        [self logFormat: @"!!! Failed to Delete doc"];
                        self.error = error;
                    }
                }
                i++;
            }
        }
      //  return YES;
    //}];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time Taken: %f",executionTime];
    self.running = NO;
}


- (void) setUp {
    [super setUp];
    [self logFormat: @"Starting Setup"];
    self.heartbeatInterval = 1.0;
     self.docs = [[NSMutableArray alloc] init];
    
    NSMutableString *str = [[NSMutableString alloc] init];
    
    for (int i = 0; i < kSizeofDocument; i++) {
        [str appendString:@"1"];
    }
    
    NSDictionary* props = @{@"k": str};
    [self.database inTransaction:^BOOL{
        for (int j = 0; j < kNumberOfDocuments; j++) {
            @autoreleasepool {
                CBLDocument* doc = [self.database createDocument];
                [self.docs addObject:doc];
                NSError* error;
                if (![doc putProperties: props error: &error]) {
                    [self logFormat: @"!!! Failed to create doc %@", props];
                    self.error = error;
                }
            }
        }
        return YES;
    }];
    
    [self logFormat: @"Finished Setup"];
    
}


@end
