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
    if (!_manager)
        _manager = [[CBLManager alloc] init];
    return _manager;
}


- (CBLDatabaseOptions*) databaseOptionsWithCreateValue: (BOOL)create {
    NSDictionary* config = [[[self class] config] objectForKey: @"database"];
    CBLDatabaseOptions* option = [[CBLDatabaseOptions alloc] init];
    NSString* storage = [config[@"storage"] lowercaseString];
    if ([storage isEqualToString: [kCBLSQLiteStorage lowercaseString]]) {
        option.storageType = kCBLSQLiteStorage;
    } else if ([storage isEqualToString: [kCBLForestDBStorage lowercaseString]]) {
        option.storageType = kCBLForestDBStorage;
    }
    option.encryptionKey = [config[@"encryption"] boolValue] ? config[@"encryptionKey"] : nil;
    option.create = create;

    return option;
}


- (CBLDatabase*) database {
    if (!_createdDatabase) {
        _createdDatabase = YES;

        NSError *error = nil;
        _database = [self createEmptyDatabaseNamed: self.databaseName error: &error];

        if (error)
            [self logFormat: @"Error creating the database %@ : %@", self.databaseName, error];
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

- (BOOL) reopenDatabase: (NSError**)error {
    if (_database) {
        if (![_database close: error])
            return NO;

        CBLDatabaseOptions* option = [self databaseOptionsWithCreateValue: NO];
        _database = [self.manager openDatabaseNamed: self.databaseName
                                        withOptions: option error: error];
        if (_database)
            return YES;
    } else
        [self logFormat: @"WARNING: No database opened before"];

    return NO;
}


- (CBLDatabase*) createEmptyDatabaseNamed: (NSString*)name error: (NSError**)outError {
    CBLDatabaseOptions* option = [self databaseOptionsWithCreateValue: NO];
    CBLDatabase* database = [self.manager openDatabaseNamed: self.databaseName
                                                withOptions: option error: NULL];
    if (database) {
        if (![database deleteDatabase: outError])
            return nil;
    }

    option = [self databaseOptionsWithCreateValue: YES];
    return [self.manager openDatabaseNamed: self.databaseName
                               withOptions: option error: outError];
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


- (NSDictionary*) classConfig {
    return [[[self class] config] objectForKey: NSStringFromClass([self class])];
}

- (id) configForKey: (NSString *)key {
    return [[self classConfig] objectForKey: key];
}


- (NSURL*) replicationUrl {
    NSString* url = [[[self class] config] objectForKey: @"replicationUrl"];
    return [NSURL URLWithString: url];
}


- (BOOL) wait: (NSTimeInterval)timeout for: (BOOL(^)())block {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime lastTime = startTime;
    BOOL done = NO;
    do {
        if (![[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                      beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]])
            break;
        // Replication runs on a background thread, so the main runloop should not be blocked.
        // Make sure it's spinning in a timely manner:
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (now-lastTime > 0.25)
            NSLog(@"Main runloop was blocked for %g sec", now-lastTime);
        lastTime = now;
        if (now-startTime > timeout)
            break;
        done = block();
    } while (!done);
    return done;
}


- (void) setUp {
    [super setUp];
    
    _createdDatabase = NO;

    [self logFormat: @"%@: config: %@", self, [self classConfig]];
}

- (void) tearDown {
    [self deleteDatabase];

    _database = nil;
    [_manager close];
    _manager = nil;

    [super tearDown];
}


@end
