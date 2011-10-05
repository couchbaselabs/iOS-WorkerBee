//
//  AppDelegate.h
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Couchbase/CouchbaseMobile.h>
@class CouchDatabase;


@interface AppDelegate : UIResponder <UIApplicationDelegate, CouchbaseDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet UINavigationController *navController;

/** The URL of the Couchbase server. */
@property (readonly, retain, nonatomic) NSURL* serverURL;

@end


extern NSString* const AppDelegateCouchRestartedNotification;
