//
//  Test13_ReduceQuery.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 3/9/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test13_ReduceQuery.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>


#define kNumberOfDocuments 1000


@implementation Test13_ReduceQuery


- (void) heartbeat {
    [self logFormat: @"Starting Test"];
    // Start measuring time from here
    NSDate *start = [NSDate date];
    
    CBLView* view = [self.database viewNamed: @"vacant"];
    
    [view setMapBlock: MAPBLOCK({
        id v = [doc objectForKey: @"vacant"];
        id name = [doc objectForKey: @"name"];
        if (v && name) emit(name, v);
    }) reduceBlock: REDUCEBLOCK({return [CBLView totalValues:values];})
              version: @"2"];
    
    
    CBLQuery* query = [[self.database viewNamed: @"vacant"] createQuery];
    query.descending = NO;
    
    NSError *error;
    CBLQueryEnumerator *rowEnum = [query run: &error];
    for (CBLQueryRow* row in rowEnum) {
        [self logFormat: @"Vacant: %@",row.value];
        //NSLog(@"name = %@ value = %@", row.key, row.value);
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time Taken: %f",executionTime];
    
    
    [view deleteIndex];
    [view deleteView];
    
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
    [self.database inTransaction:^BOOL{
        for (int i = 0; i < kNumberOfDocuments; i++) {
            
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
            }
        }
        return YES;
    }];
    self.heartbeatInterval = 0.001;
    [self logFormat: @"Completed Setup"];
}



@end