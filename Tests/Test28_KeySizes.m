//
//  Test28_ReduceQuery2.m
//  Worker Bee
//
//  Created by Li Yang on 9/3/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test28_KeySizes.h"

#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLView (Internal)
- (int) updateIndex;
@end

@implementation Test28_KeySizes

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        NSString *key = [[NSString alloc] init];
        NSString *value = [[NSString alloc] init];
        NSError *error = nil;
        NSDate *start;
        NSTimeInterval executionTimeTotal;
        NSDate* methodFinish;
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];

        @autoreleasepool {
            // Start measuring time
            start = [NSDate date];
            // Create docs
            [self.database inTransaction:^BOOL{
                for (int i = 0; i < kNumberOfDocuments; i++) {
                    @autoreleasepool {
                        NSUInteger r = arc4random_uniform(kNumberOfDocuments-1) + 1;
                        NSString* name = [NSString stringWithFormat:@"%@%@", str, @(r)];
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

            // Define view
            CBLView* view = [self.database viewNamed: @"vacant"];
            [view setMapBlock: MAPBLOCK({
                id apt = [doc objectForKey: @"apt"];
                id name = [doc objectForKey: @"name"];
                //large key, small value
                //if (apt && name) emit(name, apt);
                //small key, large value
                if (apt && name) emit(apt, name);
            }) reduceBlock: REDUCEBLOCK({
                return @([values count]);
            }) version: @"3"];

            [view updateIndex];

            // query
            CBLQuery* query = [[self.database viewNamed: @"vacant"] createQuery];
            query.mapOnly = YES;
//            query.descending = NO;
//            query.startKey = @0;
//            query.endKey = [NSNumber numberWithInt:kNumberOfDocuments];
            CBLQueryEnumerator* rowEnum = [query run: &error];
            for (CBLQueryRow* row in rowEnum) {
                @autoreleasepool {
                    key = row.key;
                    value = row.value;
                    //[self logFormat: @"--- Query return row (%@ %@)", key, value];
                }
            }

            // Reduce query
//            CBLQuery* query = [[self.database viewNamed: @"vacant"] createQuery];
//            query.mapOnly = NO;
//            CBLQueryEnumerator* rowEnum = [query run: &error];
//            CBLQueryRow *row = [rowEnum nextRow];

            methodFinish = [NSDate date];
            executionTimeTotal = [methodFinish timeIntervalSinceDate:start] * 1000;

           [self logFormat: @"--- Query return %d records", rowEnum.count];
        }
        return executionTimeTotal;
    }
    
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 0.001;
}

@end