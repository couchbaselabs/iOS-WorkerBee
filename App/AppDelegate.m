//
//  AppDelegate.m
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "AppDelegate.h"


NSString* const AppDelegateCouchRestartedNotification = @"AppDelegateCouchRestarted";


/** This is the name of the database the app will use -- customize it as you like,
    but the name must contain only *lowercase* letters, digits, and "-". */
#define kDatabaseName @"data"


@interface AppDelegate ()
@property (readwrite, retain, nonatomic) NSURL* serverURL; // settable internally
@end


@implementation AppDelegate

@synthesize window = _window, navController = _navController;
@synthesize serverURL = _serverURL;

- (void)dealloc
{
    [_window release];
    [_serverURL release];
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
    gRESTLogLevel = kRESTLogRequestURLs;   // You can increase this to kRESTLogRequestURLs or higher
    
    if (!self.serverURL)
        self.serverURL = serverURL;
    else
        [[NSNotificationCenter defaultCenter] 
                                        postNotificationName: AppDelegateCouchRestartedNotification
                                                      object: self];
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase failedToStart:(NSError*)error
{
    // TODO: You will probably want to improve this to at least display an alert box and quit!
    NSAssert(NO, @"Couchbase failed to initialize: %@", error);
}

@end
