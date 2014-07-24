//
// PerfTestScenario9.m
// Worker Bee
//
// Created by Ashvinder Singh on 2/14/14.
// Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test9_LoadDB.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>


@implementation Test9_LoadDB
{
    CBLManager* _mymanager;
    CBLDatabase* _database;
    BOOL _createdDatabase;
}

- (CBLDatabase*) mydatabase {
    if (!_createdDatabase) {
        _createdDatabase = YES;
        NSError* error = nil;
        CBLDatabase* database = [self.testmanager existingDatabaseNamed: self.dbname error: NULL];
        if (database) {
            _database = database;
        }
        _database = [_mymanager databaseNamed: self.dbname error: &error];
    }
    CBLDatabase* database = [self.testmanager existingDatabaseNamed: self.dbname error: NULL];
    if (database) {
        _database = database;
    }
    return _database;
}


- (CBLManager*) testmanager {
    if (!_mymanager) {
        _mymanager = [[CBLManager alloc] init];
    }
    return _mymanager;
}

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        self.dbname = [[NSString alloc] init];
        self.dbname = @"test9";
        
        NSMutableString *str = [[NSMutableString alloc] init];
        
        for (int i = 0; i < kSizeofDocument; i++) {
            [str appendString:@"1"];
        }
        
        NSDictionary* props = @{@"k": str};
        [self.mydatabase inTransaction:^BOOL{
            for (int j = 0; j < kNumberOfDocuments; j++) {
                @autoreleasepool {
                    CBLDocument* doc = [self.mydatabase createDocument];
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

    @autoreleasepool {
        NSDate *start = [NSDate date];
        
        // Shutdown database
        [self.mymanager close];
        self.mymanager = nil;
        
        // Recreate database
        CBLDatabase* db = [self mydatabase];
        if (!db) {
            [self logFormat:@"Error database not found"];
        }

        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        return executionTime;
    }
}



- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}

@end