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

@property (strong, nonatomic) UIWindow *window;

/** The database this app is using; observable.
    (The unit tests access this property; see CouchTestCase.m.) */
@property (readonly, retain, nonatomic) CouchDatabase* database;

@end
