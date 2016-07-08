//
//  Test03_ReadDocs.m
//  Worker Bee
//
//  Created by Pasin Suriyentrakorn on 7/7/16.
//  Copyright © 2016 Couchbase, Inc. All rights reserved.
//

#import "Test03_ReadDocs.h"

@implementation Test03_ReadDocs

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    NSInteger docSize = [[self configForKey: @"docSize"] integerValue];

    NSMutableData* data = [NSMutableData dataWithLength: docSize];
    memset(data.mutableBytes, 'a', data.length);
    NSString* content = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

    NSMutableArray* docIds = [NSMutableArray arrayWithCapacity: docSize];
    BOOL success = [self.database inTransaction: ^BOOL{
        for (int i = 0; i < numDocs; i++) {
            NSError* error;
            NSDictionary* props = @{@"content": content};
            CBLDocument* doc = [self.database createDocument];
            if (![doc putProperties: props error: &error]) {
                [self logFormat: @"ERROR: Failed to create doc : %@", error];
                return NO;
            }
            [docIds addObject: doc.documentID];
        }
        return YES;
    }];

    if (!success)
        return;

    NSError* error;
    if (![self reopenDatabase: &error]) {
         [self logFormat: @"ERROR: Failed to reopen the database : %@", error];
        return;
    }

    uint64_t t = dispatch_benchmark(1, ^{
        for (NSString* docId in docIds) {
            CBLDocument* doc = [self.database documentWithID: docId];
            if (!doc.properties) {
                [self logFormat: @"ERROR: Failed to read a document %@", error];
                break;
            }
        }
    });

    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
