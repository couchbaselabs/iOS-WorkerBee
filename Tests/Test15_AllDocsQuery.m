//
//  Test15_AllDocsQuery.m
//  Worker Bee
//
//  Created by Pasin Suriyentrakorn on 7/8/16.
//  Copyright © 2016 Couchbase, Inc. All rights reserved.
//

#import "Test15_AllDocsQuery.h"

@implementation Test15_AllDocsQuery

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
    
    uint64_t t = dispatch_benchmark(1, ^{
        CBLQuery* query = [self.database createAllDocumentsQuery];
        NSError* error;
        CBLQueryEnumerator* rows = [query run: &error];
        for (CBLQueryRow* row in rows) {
            if (!row.documentID) {
                [self logFormat: @"ERROR: Failed to enumerate the rows result"];
                break;
            }
        }
    });
    
    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
