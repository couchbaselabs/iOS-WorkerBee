//
// PerfTestScenario11.m
// Worker Bee
//
// Created by Ashvinder Singh on 2/14/14.
// Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test11_DeleteDocs.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@implementation Test11_DeleteDocs

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
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
        
    }
    
    @autoreleasepool {
        NSDate *start = [NSDate date];
        
        //Do not run this test using ‘inTransaction’ block.
        for (CBLDocument *doc in self.docs) {
            // delete document
            NSError* error;
            if (![doc deleteDocument: &error]) {
                [self logFormat: @"!!! Failed to Delete doc"];
                self.error = error;
            }
        }
        
        NSDate *methodFinish = [NSDate date];
        // The time is converted to ms, then times 1000 because the number is so small it got round to 0 often
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000000;
        return executionTime;
    }
}


- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}


@end