//
// Test12_QueryView.m
// Worker Bee
//
// Created by Ashvinder Singh on 3/6/14.
// Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test22_Query.h"
#import <malloc/malloc.h>
//
//  Test22_Query.m
//  Worker Bee
//
//  Created by Li Yang on 7/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLView (Internal)
- (int) updateIndex;
@end


@implementation Test22_Query


- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        // The kSizeofDocument affect overall size of doc, but not key size
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];

        [self.database inTransaction:^BOOL{
            for (int i = 0; i < kNumberOfDocuments; i++) {
                @autoreleasepool {
                    NSString* name = [NSString stringWithFormat:@"%@%@", @"n", @(i)];
                    bool vacant = (i+2) % 2 ? 1 : 0;
                    NSDictionary* props = @{@"name":name,
                                            @"apt": [NSString stringWithFormat:@"%@%@", str, @(i)],
                                            @"vacant":@(vacant)};
                    CBLDocument* doc = [self.database createDocument];
                    NSError* error;
                    if (![doc putProperties: props error: &error]) {
                        [self logFormat: @"!!! Failed to create doc %@", props];
                        self.error = error;
                        return NO;
                    }
                }
            }
            return YES;
        }];
    }
    
    @autoreleasepool {
        CBLView* view = [self.database viewNamed: @"vacant"];
        
        [view setMapBlock: MAPBLOCK({
            id v = [doc objectForKey: @"vacant"];
            id name = [doc objectForKey: @"name"];
            if (v && name) emit(name, v);
        }) reduceBlock: REDUCEBLOCK({return @(values.count);})
                  version: @"3"];
        
        [view updateIndex];
        
        NSDate *start = [NSDate date];
        
        start = [NSDate date];
        
        CBLQuery* query = [[self.database viewNamed: @"vacant"] createQuery];
        query.descending = NO;
        query.mapOnly = YES;
        
        NSString *key = [[NSString alloc] init];
        NSString *value = [[NSString alloc] init];
        NSError *error;
        CBLQueryEnumerator *rowEnum = [query run: &error];
        for (CBLQueryRow* row in rowEnum) {
            @autoreleasepool {
                key = row.key;
                value = row.value;
            }
        }
        
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        return executionTime;
    }
    
}

/*
 Create a fake database modeling an apartment complex have the following fields:
 Name:
 Apt#:
 Phone:
 Vacant: YES / NO
 */

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 0.001;
}



@end