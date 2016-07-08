//
// Test08_DocRevisions.m
// Worker Bee
//
// Created by Ashvinder Singh on 2/13/14.
// Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test08_DocRevisions.h"

@implementation Test08_DocRevisions

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    NSInteger numUpdates = [[self configForKey: @"numUpdates"] integerValue];
    
    NSMutableArray* docs = [NSMutableArray array];
    BOOL success = [self.database inTransaction: ^BOOL{
        for (int i = 0; i < numDocs; i++) {
            NSError* error;
            NSDictionary* props = @{@"toggle": @(YES)};
            CBLDocument* doc = [self.database createDocument];
            if (![doc putProperties: props error: &error]) {
                [self logFormat: @"ERROR: Failed to create doc : %@", error];
                return NO;
            }
            [docs addObject: doc];
        }
        return YES;
    }];
    
    if (!success)
        return;
    
    uint64_t t = dispatch_benchmark(1, ^{
        for (CBLDocument* doc in docs) {
            for (int i = 0; i < numUpdates; i++) {
                NSMutableDictionary* props = [doc.properties mutableCopy];
                BOOL wasChecked = [props[@"toggle"] boolValue];
                props[@"toggle"] = @(!wasChecked);
                
                NSError* error;
                if (![doc putProperties: props error: &error]) {
                    [self logFormat: @"ERROR: Failed to update the document : %@", error];
                    return;
                }
            }
        }
    });
    
    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}


@end