//
//  Test12_QueryView.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 3/6/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test12_QueryView.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLView (Internal)
- (int) updateIndex;
@end

#define kNumberOfDocuments 1000


@implementation Test12_QueryView


- (void) heartbeat {
     [self logFormat: @"Starting Test"];
    // Start measuring time from here
    NSDate *start = [NSDate date];

    CBLView* view = [self.database viewNamed: @"vacant"];
    
     [view setMapBlock: MAPBLOCK({
        id v = [doc objectForKey: @"vacant"];
        id name = [doc objectForKey: @"name"];
        if (v && name) emit(name, v);
     }) reduceBlock: REDUCEBLOCK({return @(values.count);})
        version: @"3"];
    
    [view updateIndex];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time Taken For Indexing: %f",executionTime];
 
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

    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time For Query: %f",executionTime];
    
    // Start measuring time for reduce query from here
    start = [NSDate date];
    
    query = [[self.database viewNamed: @"vacant"] createQuery];
    query.mapOnly = NO;
    rowEnum = [query run: &error];
    CBLQueryRow *row = [rowEnum rowAtIndex:0];
    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:start];

    [self logFormat: @"Vacant: %@",row.value ];
    [self logFormat:@"Total Time For Reduce query: %f",executionTime];
    
    [self logFormat: @"Finished Test"];
    self.running = NO;

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
     [self logFormat: @"Doing Setup"];

    NSDate* start = [NSDate date];
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
    self.heartbeatInterval = 0.001;
    [self logFormat: @"Completed Setup in %.3f sec", -[start timeIntervalSinceNow]];
}



@end
