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


@interface AppDelegate ()
@property (readwrite, retain, nonatomic) CouchDatabase* database; // settable internally
@end


@implementation AppDelegate

@synthesize window = _window, navController = _navController;
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
    [_window addSubview:_navController.view];
    [_window makeKeyAndVisible];

    // Create & configure a CouchbaseMobile instance:
    CouchbaseMobile* cb = [[CouchbaseMobile alloc] init];
    cb.delegate = self;
    
/* Uncomment this block if you want to override CouchDB settings in a custom .ini file
    NSString* iniPath = [[NSBundle mainBundle] pathForResource: @"couchdb" ofType: @"ini"];
    NSAssert(iniPath, @"Couldn't find couchdb.ini resource");
    cb.iniFilePath = iniPath;
*/
    
    // Now tell the database to start:
    if (![cb start]) {
        [self couchbaseMobile:cb failedToStart:cb.error];
        return NO;
    }

    return YES;
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase didStart:(NSURL*)serverURL
{
    gCouchLogLevel = 1;                // You can increase this to 2 (or even 3, which is overkill)
    gRESTLogLevel = kRESTLogNothing;   // You can increase this to kRESTLogRequestURLs or higher
    
    if (!self.database) {
        // Do this on launch, but not when returning to the foreground:
        CouchServer* server = [[CouchServer alloc] initWithURL:serverURL];
        // Track active operations so we can wait for their completion in didEnterBackground, below
        server.tracksActiveOperations = YES;
        CouchDatabase* database = [server databaseNamed:kDatabaseName];

        // Create the database on the first run of the app.
        if (![[database GET] wait]) {
            [[database create] wait];
        }

        self.database = database;
        [server release];
    }
    
    // For most purposes you will want to track changes.
    self.database.tracksChanges = YES;
    
	NSLog(@"Couchbase is ready, go!");
    // TODO: Now that the database is ready, add your setup code here.
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase failedToStart:(NSError*)error
{
    // TODO: You will probably want to improve this to at least display an alert box and quit!
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
