//
//  CreateDocsTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/5/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "CreateDocsTest.h"
#import <CouchbaseLite/CBLJSON.h>


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
        NSString* dateStr = [CBLJSON JSONObjectWithDate: [NSDate date]];
        NSDictionary* props = @{@"sequence": @(_sequence),
                                @"date": dateStr};
        CBLDocument* doc = [self.database createDocument];
        NSError* error;
        if (![doc putProperties: props error: &error]) {
            [self logFormat: @"!!! Failed to create doc %@", props];
            self.error = error;
        }
    }
    self.status = [NSString stringWithFormat: @"Created %i docs", _sequence];
}

- (void) setUp {
    [super setUp];
    _sequence = 0;
    self.heartbeatInterval = 1.0;
}

@end
