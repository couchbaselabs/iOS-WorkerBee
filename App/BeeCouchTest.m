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


- (NSString*) databaseName {
    return [[[[self class] testName] lowercaseString] stringByAppendingString: @"-db"];
}


- (CBLManager*) manager {
    if (!_manager) {
        //Uncomment the following 2 lines to run ForestDB
        [[NSUserDefaults standardUserDefaults] setValue:@"ForestDB" forKey:@"CBLStorageType"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _manager = [[CBLManager alloc] init];
    }
    return _manager;
}


- (CBLDatabase*) database {
    if (!_createdDatabase) {
        _createdDatabase = YES;
        NSError* error = nil;
        CBLDatabase* database = [self.manager existingDatabaseNamed: self.databaseName error: NULL];
        if (database) {
            [database deleteDatabase: &error];
        }
        _database = [_manager databaseNamed: self.databaseName error: &error];
    }
    return _database;
}


- (void) deleteDatabase {
    if (!_createdDatabase)
        return;
    NSError* error = nil;
    if (![_database deleteDatabase: &error])
        [self logFormat: @"WARNING: Couldn't delete database: %@", error];
    _database = nil;
    _createdDatabase = NO;
    _database = nil;
}


- (CBLDatabase*) createEmptyDatabaseNamed: (NSString*)name error: (NSError**)outError {
    CBLDatabase* db = [self.manager existingDatabaseNamed: name error: outError];
    if (db) {
        if (![db deleteDatabase: outError])
            return nil;
    }
    return [self.manager databaseNamed: name error: outError];
}


- (void) eraseRemoteDB: (NSURL*)dbURL {
    [self logFormat: @"Deleting %@", dbURL];

    __block NSError* error = nil;
    __block BOOL finished = NO;

    // Post to /db/_flush is supported by Sync Gateway 1.1, but not by CouchDB
    NSURLComponents *comp = [NSURLComponents componentsWithURL: dbURL resolvingAgainstBaseURL: YES];
    comp.port = @4985;
    comp.path = [comp.path stringByAppendingPathComponent: @"_flush"];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: comp.URL
                                                           cachePolicy: NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval: 60.0];
    [request setHTTPMethod:@"POST"];

    NSURLSession* session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest: request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *err) {
        finished = YES;
        error = err;
    }] resume];

    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow: 10];
    while (!finished && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                                 beforeDate: timeout])
        ;
    NSAssert(error == nil, @"Couldn't delete remote: %@", error);
}


- (void) setUp {
    [super setUp];
    
    _createdDatabase = NO;
}

- (void) tearDown {
    _database = nil;
    [_manager close];
    _manager = nil;

    [super tearDown];
}


@end
