//
//  BeeCouchTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"
#import "AppDelegate.h"


@interface BeeCouchTest ()
@property (readwrite) BOOL suspended;
@end


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


- (NSURL*) serverURL {
    NSURL* url;
    do {
        url = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).serverURL;
        if (!url) {
            NSLog(@"Waiting for server to start...");
            [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                     beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
        }
    } while (!url);
    return url;
}


- (NSString*) databaseName {
    return [[NSStringFromClass([self class]) lowercaseString] stringByAppendingString: @"-db"];
}


- (CouchServer*) server {
    if (!_server) {
        _server = [[CouchServer alloc] initWithURL: self.serverURL];
        // Track active operations so we can wait for their completion in serverWillSuspend, below
        _server.tracksActiveOperations = YES;
    }
    return _server;
}


- (CouchDatabase*) database {
    if (self.suspended)
        [self logMessage: @"WARNING: Accessing database while suspended"];
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
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver: self
             selector: @selector(serverDidResume)
                 name: AppDelegateCouchRestartedNotification
               object: nil];
}

- (void) tearDown {
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr removeObserver: self
                    name:AppDelegateCouchRestartedNotification
                  object: nil];
    [_database release];
    _database = nil;
    [_server release];
    _server = nil;
    self.suspended = NO;
    
    [super tearDown];
}


@synthesize suspended = _suspended;


- (void)applicationDidEnterBackground: (NSNotification*)notification
{
    [self serverWillSuspend];
}


- (void)applicationWillEnterForeground: (NSNotification*)notification
{
    [super applicationWillEnterForeground: notification];
    // Wait for notification that Couchbase server has restarted
    self.status = @"Waiting for server to resume...";
}


- (void)serverWillSuspend
{
    [self logMessage: @"Suspending"];
    
    self.suspended = YES;
    self.status = @"Server suspended";
    
    // Turn off the _changes watcher:
    _database.tracksChanges = NO;
    
	// Make sure all transactions complete, because going into the background will
    // close down the CouchDB server:
    [RESTOperation wait: _server.activeOperations];
}


- (void) serverDidResume {
    [self logMessage: @"Server resumed"];
    _database.tracksChanges = YES;
    self.suspended = NO;
    self.status = @"Resumed";
}


@end
