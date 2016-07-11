//
//  Test16_CompactDB.m
//  Worker Bee
//
//  Created by Pasin Suriyentrakorn on 7/8/16.
//  Copyright © 2016 Couchbase, Inc. All rights reserved.
//

#import "Test16_CompactDB.h"

@implementation Test16_CompactDB

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    NSInteger docSize = [[self configForKey: @"docSize"] integerValue];
    NSInteger numAtts = [[self configForKey: @"numAtts"] integerValue];
    NSInteger attSize = [[self configForKey: @"attSize"] integerValue];
    BOOL deleteAtts = [[self configForKey: @"deleteAtts"] boolValue];
    NSInteger numRevs = [[self configForKey: @"numRevs"] integerValue];
    
    NSString* content;
    if (docSize > 0) {
        NSMutableData* data = [NSMutableData dataWithLength: docSize];
        memset(data.mutableBytes, 'a', data.length);
        content = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    }
    
    NSMutableData* attData;
    if (attSize > 0) {
        [NSMutableData dataWithLength: attSize];
        memset(attData.mutableBytes, 'a', attData.length);
    }
    
    BOOL success = [self.database inTransaction: ^BOOL{
        for (int i = 0; i < numDocs; i++) {
            NSError* error;
            CBLDocument* doc = [self.database createDocument];
            
            CBLUnsavedRevision* rev = [doc newRevision];
            if (docSize > 0)
                rev.userProperties =  @{@"content": content};
            
            BOOL hasAttachments;
            if (numAtts > 0 && attSize > 0) {
                hasAttachments = YES;
                for (int j = 0; j < numAtts; j++) {
                    NSString* str = [NSString stringWithFormat:@"%d-%d", i, j];
                    NSData* prefix = [str dataUsingEncoding: NSUTF8StringEncoding];
                    NSMutableData *att = [NSMutableData dataWithLength: prefix.length + attData.length];
                    [att appendData: prefix];
                    [att appendData: attData];
                    [rev setAttachmentNamed: @"attach" withContentType: @"text/plain" content: att];
                }
            }
            
            if (![rev save: &error]) {
                [self logFormat: @"ERROR: Failed to create doc : %@", error];
                return NO;
            }
            
            for (int k = 0; k < numRevs; k++) {
                NSMutableDictionary* props = [doc.properties mutableCopy];
                props[@"update"] = @(k);
                CBLUnsavedRevision* rev = [doc newRevision];
                rev.properties = props;
                if (![rev save: &error]) {
                    [self logFormat: @"ERROR: Failed to update doc : %@", error];
                    return NO;
                }
            }
            
            if (deleteAtts && hasAttachments) {
                CBLUnsavedRevision* rev = [doc newRevision];
                for (NSString* name in [doc.currentRevision attachmentNames]) {
                    [rev removeAttachmentNamed: name];
                }
                if (![rev save: &error]) {
                    [self logFormat: @"ERROR: Failed to delete attachment : %@", error];
                    return NO;
                }
            }
        }
        return YES;
    }];
    
    if (!success)
        return;
    
    uint64_t t = dispatch_benchmark(1, ^{
        NSError* error;
        if (![self.database compact: &error]) {
            [self logFormat: @"ERROR: Failed to compact database : %@", error];
        }
    });
    
    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
