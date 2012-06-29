//
//  AppDelegate.m
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "CouchbaseStartupTest.h"


@implementation AppDelegate


@synthesize window = _window, navController = _navController;


- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"------ application:didFinishLaunchingWithOptions:");
    [_window addSubview:_navController.view];
    [_window makeKeyAndVisible];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

    //gCouchLogLevel = 1;
    //gRESTLogLevel = kRESTLogRequestURLs;
    
    NSError* error = [[CouchTouchDBServer sharedInstance] error];
    if (error) {
        NSString* message = [NSString stringWithFormat: @"TouchDB failed to initialize:\n\n%@.",
                             error.localizedDescription];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Fatal Error"
                                                        message: message
                                                       delegate: self
                                              cancelButtonTitle: @"Quit"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    exit(0);
}

@end
