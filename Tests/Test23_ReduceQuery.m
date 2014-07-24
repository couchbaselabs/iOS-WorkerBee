//
// Test12_QueryView.m
// Worker Bee
//
// Created by Ashvinder Singh on 3/6/14.
// Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test23_ReduceQuery.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLView (Internal)
- (int) updateIndex;
@end


@implementation Test23_ReduceQuery


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
        NSDate *start = [NSDate date];
        
        CBLView* view = [self.database viewNamed: @"vacant"];
        
        [view setMapBlock: MAPBLOCK({
            id v = [doc objectForKey: @"vacant"];
            id name = [doc objectForKey: @"name"];
            if (v && name) emit(name, v);
        }) reduceBlock: REDUCEBLOCK({return @(values.count);})
                  version: @"3"];
        
        [view updateIndex];
        NSError *error = nil;
        
        // Start measuring time for reduce query from here
        start = [NSDate date];
        
        CBLQuery* query = [[self.database viewNamed: @"vacant"] createQuery];
        query.mapOnly = NO;

        CBLQueryEnumerator* rowEnum = [query run: &error];
        CBLQueryRow *row = [rowEnum rowAtIndex:0];
        
        NSDate* methodFinish = [NSDate date];
        NSTimeInterval executionTimeTotal = [methodFinish timeIntervalSinceDate:start] * 1000;
        
        [self logFormat: @"Query result - Vacant: %@",row.value ];
        return executionTimeTotal;
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