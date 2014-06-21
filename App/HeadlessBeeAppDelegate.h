//
//  HeadlessBeeAppDelegate.h
//  Worker Bee
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HeadlessBeeAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic) UIWindow* window;
@property (readonly) NSDictionary* config;
@end
