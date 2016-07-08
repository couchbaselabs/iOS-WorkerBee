//
//  BeeCouchTest.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTest.h"
#import <CouchbaseLite/CouchbaseLite.h>


/** Subclass of BeeTest for exercising CouchbaseLite. */
@interface BeeCouchTest : BeeTest

/** Expose the private dispatch_benchmark used for measuring the performance. */
extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

#pragma mark For subclasses to call:

/** The top-level Couchbase Lite object. */
@property (readonly) CBLManager* manager;

/** A database to use for your test.
    The database will be existent but empty at the start of the test.
    (Actually the database is created on demand the first time you call this method. If you'd rather create the database yourself some other way, or use multiple databases, you don't need to call this method.) */
@property (readonly) CBLDatabase* database;

/** The name of the database to create.
    Defaults to the class name lowercased with "-db" appended.
    You can override this method to use a different name. */
@property (readonly) NSString* databaseName;

/** Deletes the test database. The next call to the .database property will create and return a
    new, empty CBLDatabase instance.
    This is useful if you'd like to run several sub-tests, each starting with an empty database. */
- (void) deleteDatabase;

- (BOOL) reopenDatabase: (NSError**)error;

/** Create an empty database with name. If the database exists, the database will be deleted before
 a new database with the specified name is created. */
- (CBLDatabase*) createEmptyDatabaseNamed: (NSString*)name error: (NSError**)outError;

/** Deletes a remote database. Works only with CouchDB, not Sync Gateway. */
- (void) eraseRemoteDB: (NSURL*)dbURL;

/** Returns 'test-class' config value based on the given key */
- (id) configForKey: (NSString*)key;

/** Returns replication URL configured in the config file */
- (NSURL*) replicationUrl;

/** A utility method for waiting until the condition returned by the the block code is true. */
- (BOOL) wait: (NSTimeInterval)timeout for: (BOOL(^)())block;

@end
