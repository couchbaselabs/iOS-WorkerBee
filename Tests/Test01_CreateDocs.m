//
//  Test01_CreateDocs.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 1/31/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import "Test01_CreateDocs.h"

@implementation Test01_CreateDocs

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    NSInteger docSize = [[self configForKey: @"docSize"] integerValue];

    NSMutableData* data = [NSMutableData dataWithLength: docSize];
    memset(data.mutableBytes, 'a', data.length);
    NSString* content = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

    uint64_t t = dispatch_benchmark(1, ^{
        [self.database inTransaction:^BOOL{
            for (int i = 0; i < numDocs; i++) {
                NSError* error;
                NSDictionary* props = @{@"content": content};
                CBLDocument* doc = [self.database createDocument];
                if (![doc putProperties: props error: &error]) {
                    [self logFormat: @"Failed to create doc : %@", error];
                    return NO;
                }
            }
            return YES;
        }];
    });

    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
