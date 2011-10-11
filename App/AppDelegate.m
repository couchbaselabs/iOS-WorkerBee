//
//  AppDelegate.m
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "CouchbaseStartupTest.h"


NSString* const AppDelegateCouchStartedNotification = @"AppDelegateCouchStarted";
NSString* const AppDelegateCouchRestartedNotification = @"AppDelegateCouchRestarted";


@interface AppDelegate ()
@property (readwrite, retain, nonatomic) NSURL* serverURL; // settable internally
@end


@implementation AppDelegate
{
    BeeTest* _startupTest;
}

@synthesize window = _window, navController = _navController;
@synthesize serverURL = _serverURL, startupTest = _startupTest;

- (void)dealloc
{
    [_window release];
    [_serverURL release];
    [_startupTest release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"------ application:didFinishLaunchingWithOptions:");
    [_window addSubview:_navController.view];
    [_window makeKeyAndVisible];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

    // Create & configure a CouchbaseMobile instance:
    CouchbaseMobile* cb = [[CouchbaseMobile alloc] init];
    cb.delegate = self;
    
/* Uncomment this block if you want to override CouchDB settings in a custom .ini file
    NSString* iniPath = [[NSBundle mainBundle] pathForResource: @"couchdb" ofType: @"ini"];
    NSAssert(iniPath, @"Couldn't find couchdb.ini resource");
    cb.iniFilePath = iniPath;
*/
    
    _startupTest = [[CouchbaseStartupTest alloc] init];
    _startupTest.running = YES;

    // Now tell the database to start:
    if (![cb start]) {
        [self couchbaseMobile:cb failedToStart:cb.error];
        return NO;
    }

    return YES;
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase didStart:(NSURL*)serverURL
{
    gCouchLogLevel = 1;
    gRESTLogLevel = kRESTLogRequestURLs;
    NSString* notName;
    if (!self.serverURL) {
        self.serverURL = serverURL;
        _startupTest.running = NO;
        notName = AppDelegateCouchStartedNotification;
    } else {
        notName = AppDelegateCouchRestartedNotification;
    }
    [[NSNotificationCenter defaultCenter]  postNotificationName: notName object: self];
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase failedToStart:(NSError*)error
{
    NSString* message = [NSString stringWithFormat: @"Couchbase failed to initialize:\n\n%@.",
                         error.localizedDescription];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Fatal Error"
                                                    message: message
                                                   delegate: self
                                          cancelButtonTitle: @"Quit"
                                          otherButtonTitles: nil];
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    exit(0);
}

@end
