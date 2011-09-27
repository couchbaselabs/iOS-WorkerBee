//
//  AppDelegate.m
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <CouchCocoa/CouchCocoa.h>


/** This is the name of the database the app will use -- customize it as you like,
    but the name must contain only *lowercase* letters, digits, and "-". */
#define kDatabaseName @"data"


@implementation AppDelegate

@synthesize window = _window;
@synthesize database = _database;

- (void)dealloc
{
    [_window release];
    [_database release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"------ application:didFinishLaunchingWithOptions:");
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    // Create & configure a CouchbaseMobile instance:
    CouchbaseMobile* cb = [[CouchbaseMobile alloc] init];
    cb.delegate = self;
    
/* Uncomment this block if you want to override CouchDB settings in a custom .ini file
    NSString* iniPath = [[NSBundle mainBundle] pathForResource: @"couchdb" ofType: @"ini"];
    NSAssert(iniPath, @"Couldn't find couchdb.ini resource");
    NSLog(@"Registering custom .ini file %@", iniPath);
    cb.iniFilePath = iniPath;
*/
    
    // Now tell the database to start:
    if (![cb start])
        [self couchbaseMobile:cb failedToStart:cb.error];

    return YES;
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase didStart:(NSURL*)serverURL
{
	NSLog(@"Couchbase is Ready, go!");

    gCouchLogLevel = 2;
    gRESTLogLevel = 1;
    
    if (!self.database) {
        // Do this on launch, but not when returning to the foreground:
        CouchServer* server = [[CouchServer alloc] initWithURL:serverURL];
        // Track active operations so we can wait for their completion in didEnterBackground, below
        server.tracksActiveOperations = YES;
        CouchDatabase* database = [server databaseNamed: kDatabaseName];
        self.database = database;
        [server release];

        // Create the database on the first run of the app.
        if (![[database GET] wait]) {
            [[database create] wait];
        }
    }
    
    // For most purposes you will want to track changes.
    self.database.tracksChanges = YES;
    
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase failedToStart:(NSError*)error
{
    NSAssert(NO, @"Couchbase failed to initialize: %@", error);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"------ applicationDidEnterBackground");
    // Turn off the _changes watcher:
    self.database.tracksChanges = NO;
    
	// Make sure all transactions complete, because going into the background will
    // close down the CouchDB server:
    [RESTOperation wait: self.database.server.activeOperations];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"------ applicationWillEnterForeground");
    // Don't reconnect to the server yet ... wait for it to tell us it's back up,
    // by calling couchbaseMobile:didStart: again.
}

@end
