//
//  NullTest.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTest.h"

@interface CountTest : BeeTest

@property int count;
@property int limit;

@end


@interface ShortCountTest : CountTest
@end