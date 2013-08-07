//
//  BeeCouchTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"
#import "AppDelegate.h"


@implementation BeeCouchTest
{
    CBLManager* _manager;
    CBLDatabase* _database;
    BOOL _createdDatabase;
}


+ (BOOL) isAbstractTest {
    return self == [BeeCouchTest class];
}


- (void)dealloc {
    [_manager release];
    [super dealloc];
}


- (NSString*) databaseName {
    return [[[[self class] testName] lowercaseString] stringByAppendingString: @"-db"];
}


- (CBLManager*) manager {
    if (!_manager) {
        _manager = [[CBLManager alloc] init];
    }
    return _manager;
}


- (CBLDatabase*) database {
    if (!_createdDatabase) {
        _createdDatabase = YES;
        NSError* error = nil;
        CBLDatabase* database = [self.manager databaseNamed: self.databaseName error: NULL];
        if (database) {
            [database deleteDatabase: &error];
        }
        database = [_manager createDatabaseNamed: self.databaseName error: &error];
        _database = [database retain];
    }
    return _database;
}


- (void) setUp {
    [super setUp];
    
    _createdDatabase = NO;
}

- (void) tearDown {
    [_database release];
    _database = nil;
    [_manager release];
    _manager = nil;

    [super tearDown];
}


@end
