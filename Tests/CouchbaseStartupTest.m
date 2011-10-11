//
//  CouchbaseStartupTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/11/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "CouchbaseStartupTest.h"

@implementation CouchbaseStartupTest

+ (BOOL) isAbstractTest {
    return self == [CouchbaseStartupTest class];
    // It's not actually abstract, but we don't want it to show up in the UI.
}

@end
