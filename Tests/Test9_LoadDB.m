//
//  PerfTestScenario9.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/14/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test9_LoadDB.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

#define kNumberOfDocuments 1
// size in bytes
#define kSizeofDocument 50000000
#define kShutAndReloadDatbase 1


@implementation Test9_LoadDB

- (void) heartbeat {
    
    [self logFormat: @"heartbeat"];
    
    NSDate *start = [NSDate date];

    for (int i = 0; i < kShutAndReloadDatbase; i++) {
        [self.manager close];
        [self tearDown];
        
        [self setUp];
        CBLDatabase* db = [self database];
        
        if (!db) {
            [self logFormat:@"Error database not found"];
        }
        
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
    
    [self logFormat:@"DBName %@",self.dbname];
    
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
