//
//  Test04_CreateAttachments.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/7/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import "Test04_CreateAttachments.h"

@implementation Test04_CreateAttachments

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    NSInteger docSize = [[self configForKey: @"attSize"] integerValue];

    NSMutableData* data = [NSMutableData dataWithLength: docSize];
    memset(data.mutableBytes, 'a', data.length);

    uint64_t t = dispatch_benchmark(1, ^{
        [self.database inTransaction: ^BOOL{
            for (int i = 0; i < numDocs; i++) {
                NSData* prefix = [NSData dataWithBytes: &i length: sizeof(i)];
                NSMutableData *content = [NSMutableData dataWithLength: prefix.length + data.length];
                [content appendData: prefix];
                [content appendData: data];

                NSError* error;
                CBLDocument* doc = [self.database createDocument];
                CBLUnsavedRevision* rev = [doc newRevision];
                [rev setAttachmentNamed: @"attch" withContentType: @"text/plain" content: content];
                if (![rev save: &error]) {
                    [self logFormat: @"ERROR: Failed to create doc : %@", error];
                    return NO;
                }
            }
            return YES;
        }];
    });

    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
