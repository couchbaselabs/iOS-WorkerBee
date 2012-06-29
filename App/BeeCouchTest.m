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
    CouchServer* _server;
    CouchDatabase* _database;
    BOOL _createdDatabase;
}


+ (BOOL) isAbstractTest {
    return self == [BeeCouchTest class];
}


- (void)dealloc {
    [_server release];
    [super dealloc];
}


- (NSString*) databaseName {
    return [[[[self class] testName] lowercaseString] stringByAppendingString: @"-db"];
}


- (CouchServer*) server {
    if (!_server) {
        _server = [[CouchTouchDBServer alloc] init];
        // Track active operations so we can wait for their completion in serverWillSuspend, below
        _server.tracksActiveOperations = YES;
    }
    return _server;
}


- (CouchDatabase*) database {
    if (!_createdDatabase) {
        _createdDatabase = YES;
        CouchDatabase* database = [self.server databaseNamed: self.databaseName];
        NSAssert(database, @"Failed to create CouchDatabase object");
        // Delete and re-create the database:
        RESTOperation* op = [database DELETE];
        if ([op wait] || op.httpStatus == 404) {
            op = [database create];
            [op wait];
        }
        if (op.error) {
            self.error = op.error;
            return nil;
        }
        database.tracksChanges = YES;
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
    [_server release];
    _server = nil;

    [super tearDown];
}


@end
