//
//  Test05_ReadAttachments.m
//  Worker Bee
//
//  Created by Pasin Suriyentrakorn on 7/7/16.
//  Copyright © 2016 Couchbase, Inc. All rights reserved.
//

#import "Test05_ReadAttachments.h"

@implementation Test05_ReadAttachments

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    NSInteger attSize = [[self configForKey: @"attSize"] integerValue];

    NSMutableData* data = [NSMutableData dataWithLength: attSize];
    memset(data.mutableBytes, 'a', data.length);

    NSMutableArray* docs = [NSMutableArray arrayWithCapacity: numDocs];
    [self.database inTransaction:^BOOL{
        for (int i = 0; i < numDocs; i++) {
            NSData* prefix = [NSData dataWithBytes: &i length: sizeof(i)];
            NSMutableData *content = [NSMutableData dataWithLength: prefix.length + data.length];
            [content appendData: prefix];
            [content appendData: data];

            NSError* error;
            CBLDocument* doc = [self.database createDocument];
            CBLUnsavedRevision* rev = [doc newRevision];
            [rev setAttachmentNamed: @"attach" withContentType: @"text/plain" content: content];
            if (![rev save: &error]) {
                [self logFormat: @"ERROR: Failed to create doc : %@", error];
                return NO;
            }
            [docs addObject: doc];
        }
        return YES;
    }];

    uint64_t t = dispatch_benchmark(1, ^{
        for (CBLDocument* doc in docs) {
            CBLAttachment* att = [[doc currentRevision] attachmentNamed: @"attach"];
            if (att.content.length == 0) {
                [self logFormat: @"ERROR: Failed to read an attchment"];
                break;
            }
        }
    });

    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
