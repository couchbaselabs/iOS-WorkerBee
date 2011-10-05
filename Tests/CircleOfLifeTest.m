//
//  CircleOfLifeTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "CircleOfLifeTest.h"

@implementation CircleOfLifeTest
{
    int _sequence;
}


- (void) doSomethingSoon {
    if (self.running)
        [self performSelector: @selector(doSomething) withObject: nil afterDelay: 1.0];
}

- (void) doSomething {
    if (!self.suspended) {
        ++_sequence;
        NSString* dateStr = [RESTBody JSONObjectWithDate: [NSDate date]];
        NSDictionary* props = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt: _sequence], @"sequence",
                               dateStr, @"date", nil];
        [self logFormat: @"Adding doc: %@", props];
        CouchDocument* doc = [self.database untitledDocument];
        RESTOperation* op = [doc putProperties: props];
        [op onCompletion: ^{
            if (op.error)
                self.error = op.error;
            else
                [self logFormat: @"..._id = %@", doc.documentID];
        }];
    }
    [self doSomethingSoon];
}

- (void) setUp {
    [super setUp];
    _sequence = 0;
    [self doSomething];
}

- (void) tearDown {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [super tearDown];
}


@end
