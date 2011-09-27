//
//  CouchTestCase.h
//  Empty App
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
@class CouchDatabase;


// Utility that waits for a RESTOperation to complete and raises an assertion failure if
// it got an error. Else returns the operation.
#define AssertWait(OP) ({RESTOperation* i_op = (OP);\
                        STAssertTrue([i_op wait], @"%@ failed: %@", i_op, i_op.error);\
                        i_op = i_op;})


/** A base unit-test class for CouchCocoa apps.
    Provides an accessor for the database. */
@interface CouchTestCase : SenTestCase
{
    CouchDatabase* _db;
}

/** The database the AppDelegate is using. */
@property (nonatomic, readonly) CouchDatabase* db;

@end
