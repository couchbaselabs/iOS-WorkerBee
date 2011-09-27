//
//  Empty_AppTests.m
//  Empty AppTests
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "CouchTestCase.h"
#import <CouchCocoa/CouchCocoa.h>


@interface Empty_AppTests : CouchTestCase
@end


@implementation Empty_AppTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    // As a simple example, test that a basic GET of the database works.
    RESTOperation* op = AssertWait([self.db GET]);
    NSDictionary* info = op.responseBody.fromJSON;
    NSLog(@"Database info = %@", info);
}

@end
