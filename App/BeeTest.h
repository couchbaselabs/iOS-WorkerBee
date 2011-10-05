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
@property (readonly) NSError* error;
@property (readonly) NSArray* messages;

- (void) logMessage: (NSString*)message;
- (void) logFormat: (NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (BOOL) addTimestamp: (NSString*)message;
- (void) clearMessages;

@end
