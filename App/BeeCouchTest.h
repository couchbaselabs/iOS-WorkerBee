//
//  BeeCouchTest.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTest.h"
#import <CouchCocoa/CouchCocoa.h>


/** Subclass of BeeTest for exercising CouchCocoa. */
@interface BeeCouchTest : BeeTest

/** The embedded Couchbase server. */
@property (readonly) CouchServer* server;

/** A database to use for your test.
    The database will be existent but empty at the start of the test.
    (Actually the database is created on demand the first time you call this method. If you'd rather create the database yourself some other way, or use multiple databases, you don't need to call this method.) */
@property (readonly) CouchDatabase* database;

/** The URL of the embedded Couchbase server.
    You can access this directly, instead of the .server property, if you don't want to use a CouchServer object. */
@property (readonly) NSURL* serverURL;

/** The name of the database to create.
    Defaults to the class name lowercased with "-db" appended.
    You can override this method to use a different name. */
@property (readonly) NSString* databaseName;

/** Is the database server currently suspended (i.e. is the app in the background)?
    If this is YES you should not access the server. (Observable.) */
@property (readonly) BOOL suspended;

/** Called when the application enters the background.
    You can override this to do extra work, but call the inherited method *at the end*. */
- (void)serverWillSuspend;

/** Called when the server resumes after the app returns to the foreground.
    You can override this to do extra work, but call the inherited method first. */
- (void) serverDidResume;

@end
