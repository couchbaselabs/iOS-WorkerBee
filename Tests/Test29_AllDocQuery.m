//
//  Test29-AllDocQuery.m
//  Worker Bee
//
//  Created by Li Yang on 9/5/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test29_AllDocQuery.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@implementation Test29_AllDocQuery

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        NSError *error = nil;
        NSString *key = [[NSString alloc] init];
        NSString *value = [[NSString alloc] init];
        NSDate *start = [NSDate date];
        NSTimeInterval executionTimeTotal;

        // Create docs
        // The kSizeofDocument affect overall size of doc, but not key size
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];        [self.database inTransaction:^BOOL{
            for (int i = 0; i < kNumberOfDocuments; i++) {
                @autoreleasepool {
                    NSUInteger r = arc4random_uniform(kNumberOfDocuments-1) + 1;
                    NSString* name = [NSString stringWithFormat:@"%@%@", str, @(r)];
                    bool vacant = (i+2) % 2 ? 1 : 0;
                    NSDictionary* props = @{@"name":name,
                                            @"apt": [NSString stringWithFormat:@"%@%@", str, @(i)],
                                            @"vacant":@(vacant)};
                    CBLDocument* doc = [self.database createDocument];
                    [self.docs addObject:doc];
                    NSError* error;
                    if (![doc putProperties: props error: &error]) {
                        [self logFormat: @"!!! Failed to create doc %@", props];
                        self.error = error;
                        return NO;
                    }
                    if (![doc deleteDocument: &error]) {
                        [self logFormat: @"!!! Failed to Delete doc"];
                        self.error = error;
                    }
                }
            }
            return YES;
        }];

        // Start measuring time
        start = [NSDate date];

        // All doc query
        CBLQuery* query = [self.database createAllDocumentsQuery];
        //query.allDocsMode = kCBLAllDocs;
        query.allDocsMode = kCBLIncludeDeleted;
        //query.allDocsMode = kCBLOnlyConflicts;
        //query.allDocsMode = kCBLShowConflicts;
        CBLQueryEnumerator* rowEnum = [query run: &error];
        for (CBLQueryRow* row in rowEnum) {
            @autoreleasepool {
                key = row.key;
                value = row.value;
            }
        }

        NSDate* methodFinish = [NSDate date];
        executionTimeTotal = [methodFinish timeIntervalSinceDate:start] * 1000;

        //[self logFormat: @"Query result count - %u",(unsigned int)rowEnum.count];

        return executionTimeTotal;
    }
}


- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 0.001;
}



@end