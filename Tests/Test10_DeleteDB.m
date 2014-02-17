//
//  PerfTestScenario10.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/14/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test10_DeleteDB.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

#define kNumberOfDocuments 1
// size in bytes
#define kSizeofDocument 10

@implementation Test10_DeleteDB


- (void) heartbeat {
    
    [self logFormat: @"heartbeat"];
    
    NSDate *start = [NSDate date];
    
    NSError* error = nil;

    [self.database deleteDatabase: &error];
    if (error) {
        [self logFormat:@"Error deleting database"];
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time Taken: %f",executionTime];
    self.running = NO;
    
}





- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
    
    self.dbname = [[NSString alloc] init];
    self.dbname = self.database.name;
    
    NSMutableString *str = [[NSMutableString alloc] init];
    
    for (int i = 0; i < kSizeofDocument; i++) {
        [str appendString:@"1"];
    }
    
    NSDictionary* props = @{@"k": str};
    
    [self.database inTransaction:^BOOL{
        for (int j = 0; j < kNumberOfDocuments; j++) {
            @autoreleasepool {
                CBLDocument* doc = [self.database createDocument];
                NSError* error;
                if (![doc putProperties: props error: &error]) {
                    [self logFormat: @"!!! Failed to create doc %@", props];
                    self.error = error;
                }
            }
        }
        return YES;
    }];
}
     
     


@end
