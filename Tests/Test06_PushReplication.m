//
//  Test06_PushReplication.m
//  Worker Bee
//
//  Created by Pasin Suriyentrakorn on 7/8/16.
//  Copyright © 2016 Couchbase, Inc. All rights reserved.
//

#import "Test06_PushReplication.h"

@implementation Test06_PushReplication

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    NSInteger docSize = [[self configForKey: @"docSize"] integerValue];
    NSInteger attSize = [[self configForKey: @"attSize"] integerValue];
    
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
    
    NSMutableArray* docs = [NSMutableArray arrayWithCapacity: numDocs];
    [self.database inTransaction:^BOOL{
        for (int i = 0; i < numDocs; i++) {
            NSError* error;
            CBLDocument* doc = [self.database createDocument];
            
            CBLUnsavedRevision* rev = [doc newRevision];
            if (docSize > 0)
                rev.userProperties =  @{@"content": content};
            
            if (attSize > 0) {
                NSData* prefix = [NSData dataWithBytes: &i length: sizeof(i)];
                NSMutableData *att = [NSMutableData dataWithLength: prefix.length + attData.length];
                [att appendData: prefix];
                [att appendData: attData];
                [rev setAttachmentNamed: @"attach" withContentType: @"text/plain" content: att];
            }
            
            if (![rev save: &error]) {
                [self logFormat: @"ERROR: Failed to create doc : %@", error];
                return NO;
            }
            [docs addObject: doc];
        }
        return YES;
    }];
    
    uint64_t t = dispatch_benchmark(1, ^{
        CBLReplication* push = [self.database createPushReplication: [self replicationUrl]];
        [push start];
        BOOL done = [self wait: 600 for: ^BOOL{
            return push.status == kCBLReplicationStopped || push.lastError != nil;
        }];
        
        [self logFormat: @"Replication status: %d/%d completion; Error: %@",
            push.completedChangesCount, push.changesCount, push.lastError];
        
        if (!done)
            [self logFormat: @"ERROR: Timeout waiting for the replication to finish"];
    });
    
    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
