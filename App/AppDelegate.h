//
//  AppDelegate.h
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Couchbase/CouchbaseMobile.h>
@class CouchDatabase, BeeTest;


@interface AppDelegate : UIResponder <UIApplicationDelegate, CouchbaseDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet UINavigationController *navController;

/** The URL of the Couchbase server. */
@property (readonly, retain, nonatomic) NSURL* serverURL;
@property (readonly, retain, nonatomic) BeeTest* startupTest;

@end


extern NSString* const AppDelegateCouchStartedNotification;
extern NSString* const AppDelegateCouchRestartedNotification;
