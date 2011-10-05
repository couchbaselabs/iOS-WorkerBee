//
//  NullTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "CountTest.h"

@implementation CountTest

@synthesize count = _count, limit = _limit;

- (void) logSoon {
    [self performSelector: @selector(logSomething) withObject: nil afterDelay: 1.0];
}

- (void) logSomething {
    [self logFormat: @"Hi there! %i", ++_count, 45];
    if (_count % 5 == 0)
        self.status = [NSString stringWithFormat: @"Reached %i", _count];
    if (_limit == 0 || _count < _limit)
        [self logSoon];
    else {
        self.errorMessage = @"O noes, count overflowed!!!";
        self.running = NO;
    }
}

- (void) setUp {
    [super setUp];
    _count = 0;
    [self logSoon];
}

- (void) tearDown {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [super tearDown];
}

@end


@implementation ShortCountTest

- (id)init {
    self = [super init];
    if (self) {
        self.limit = 10;
    }
    return self;
}

@end