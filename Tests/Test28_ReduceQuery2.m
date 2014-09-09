//
//  Test28_ReduceQuery2.m
//  Worker Bee
//
//  Created by Li Yang on 9/3/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test28_ReduceQuery2.h"

#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLView (Internal)
- (int) updateIndex;
@end


@implementation Test28_ReduceQuery2


- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        [self.database inTransaction:^BOOL{
            for (int i = 0; i < kNumberOfDocuments; i++) {
                @autoreleasepool {
                    NSString* name = [NSString stringWithFormat:@"%@%@", @"n", @(i)];
                    bool vacant = (i+2) % 2 ? 1 : 0;
                    NSDictionary* props = @{@"name":name,
                                            @"apt": @(i),
                                            @"phone":@(408100000+i),
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
//        CBLView* view = [self.database viewNamed: @"vacant"];

//        [view setMapBlock: MAPBLOCK({
//            id v = [doc objectForKey: @"vacant"];
//            id name = [doc objectForKey: @"name"];
//            if (v && name) emit(name, v);
//        }) reduceBlock: REDUCEBLOCK({return @(values.count);})
//                  version: @"3"];

        // Create a view and register its map and reduce functions:
        CBLView* view = [self.database viewNamed: @"phones"];
        [view
         setMapBlock: MAPBLOCK({
            for (NSString* phone in doc[@"phones"]) {
                emit(phone, doc[@"name"]);
            }
        })
        reduceBlock:REDUCEBLOCK( {
            return @(values.count);
        })
         version: @"2"];

        [view updateIndex];

        NSDate *start = [NSDate date];

        start = [NSDate date];

        CBLQuery* query = [[self.database viewNamed: @"vacant"] createQuery];
//        query.descending = NO;
//        query.mapOnly = YES;
//
//        NSString *key = [[NSString alloc] init];
//        NSString *value = [[NSString alloc] init];
//        NSError *error;
//        CBLQueryEnumerator *rowEnum = [query run: &error];
//        for (CBLQueryRow* row in rowEnum) {
//            @autoreleasepool {
//                key = row.key;
//                value = row.value;
//            }
//        }

        query.mapOnly = NO;
         NSError *error;
        CBLQueryRow* aggregate = [[query run: &error] nextRow];
        NSLog(@"========== Average order was $%@", aggregate.value);

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


