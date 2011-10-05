//
//  NullTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "NullTest.h"

@implementation NullTest
{
    int _count;
}

- (void) logSoon {
    [self performSelector: @selector(logSomething) withObject: nil afterDelay: 1.0];
}

- (void) logSomething {
    [self logFormat: @"Hi there! %i", ++_count, 45];
    [self logSoon];
}

- (void) setRunning:(BOOL)running {
    [super setRunning: running];
    if (running)
        [self logSoon];
    else
        [NSObject cancelPreviousPerformRequestsWithTarget: self];
}

@end
