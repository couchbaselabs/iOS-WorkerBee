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

#pragma mark For subclasses to call:

/** The embedded TouchDB server. */
@property (readonly) CBLManager* manager;

/** A database to use for your test.
    The database will be existent but empty at the start of the test.
    (Actually the database is created on demand the first time you call this method. If you'd rather create the database yourself some other way, or use multiple databases, you don't need to call this method.) */
@property (readonly) CBLDatabase* database;

/** The name of the database to create.
    Defaults to the class name lowercased with "-db" appended.
    You can override this method to use a different name. */
@property (readonly) NSString* databaseName;

@end
