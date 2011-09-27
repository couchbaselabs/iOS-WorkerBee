//
//  CouchTestCase.m
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "CouchTestCase.h"
#import "AppDelegate.h"
#import <CouchCocoa/CouchCocoa.h>

@implementation CouchTestCase

@synthesize db = _db;

- (void)setUp
{
    [super setUp];
    
    // The unit tests will probably start running before the Couchbase Mobile server thread is
    // ready. So wait till the app delegate sets up its database:
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    STAssertNotNil(appDelegate, @"Missing app delegate");
    _db = appDelegate.database;
    if (!_db) {
        NSLog(@"Empty_AppTests: Waiting for database...");
        NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow: 10.0];
        while (!_db && [timeout timeIntervalSinceNow] > 0) {
            [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
            _db = appDelegate.database;
        }
        STAssertNotNil(_db, @"Couchbase Mobile failed to start", nil);
        NSLog(@"Empty_AppTests: Database ready!\n\n");
    }
}

@end
