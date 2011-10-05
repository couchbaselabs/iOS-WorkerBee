//
//  BeeTest.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BeeTest;


@protocol BeeTestDelegate <NSObject>
- (void) beeTest: (BeeTest*)test isRunning: (BOOL)running;
- (void) beeTest: (BeeTest*)test loggedMessage: (NSString*)message;
@end


@interface BeeTest : NSObject

/** Returns an array of Class objects for each available BeeTest subclass. */
+ (NSArray*) allTestClasses;

/** The name to display for a test class. Defaults to the class's name. */
+ (NSString*) displayName;


@property (assign) id<BeeTestDelegate> delegate;

@property BOOL running;
@property (copy) NSString* status;
@property (copy) NSError* error;
@property (copy) NSString* errorMessage;
@property (readonly) NSArray* messages;

@property (readonly, retain) NSDate* startTime;
@property (readonly, retain) NSDate* endTime;

- (void) clearMessages;

#pragma mark For subclasses to override:

- (void) setUp;
- (void) tearDown;

- (void)applicationDidEnterBackground: (NSNotification*)notification;
- (void)applicationWillEnterForeground: (NSNotification*)notification;

#pragma mark For subclasses to call:

- (void) logMessage: (NSString*)message;
- (void) logFormat: (NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (BOOL) addTimestamp: (NSString*)message;

@property NSTimeInterval heartbeatInterval;

- (void) heartbeat;

@end
