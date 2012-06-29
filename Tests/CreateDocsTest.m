//
//  CreateDocsTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "CreateDocsTest.h"

#define kDocumentBatchSize 100


@implementation CreateDocsTest
{
    int _sequence;
}

- (void) heartbeat {
    [self logFormat: @"Adding docs %i--%i ...",
                     _sequence+1, _sequence+kDocumentBatchSize];
    for (int i = 0; i < kDocumentBatchSize; i++) {
        ++_sequence;
        NSString* dateStr = [RESTBody JSONObjectWithDate: [NSDate date]];
        NSDictionary* props = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt: _sequence], @"sequence",
                               dateStr, @"date", nil];
        CouchDocument* doc = [self.database untitledDocument];
        RESTOperation* op = [doc putProperties: props];
        [op onCompletion: ^{
            if (op.error) {
                [self logFormat: @"!!! Failed to create doc %@", props];
                self.error = op.error;
            }
        }];
    }
    self.status = [NSString stringWithFormat: @"Created %i docs", _sequence];
}

- (void) setUp {
    [super setUp];
    _sequence = 0;
    self.heartbeatInterval = 1.0;
}

@end
