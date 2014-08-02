//
//  PerfTestScenario2.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/7/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import <malloc/malloc.h>
#import "Test3_CreateDocsWithAttachments.h"
#import <CouchbaseLite/CouchbaseLite.h>

@implementation Test3_CreateDocsWithAttachments

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeOfAttachment {
    @autoreleasepool {
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeOfAttachment];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];

        NSDate *start = [NSDate date];
        [self.database inTransaction:^BOOL{
            for (int j = 0; j < kNumberOfDocuments; j++) {
                NSString *key = [NSString stringWithFormat:@"%d",j];
                @autoreleasepool {
                    CBLDocument* doc = [self.database createDocument];
                    CBLUnsavedRevision* rev = doc.newRevision;
                    [rev setAttachmentNamed:key withContentType:@"image/jpg" content:data];

                    NSError* error;
                    CBLSavedRevision* saved = [rev save:&error];

                    if (!saved){
                        [self logFormat: @"!!! Failed to attach %@", data];
                        self.error = error;
                    }
                }
            }
            return YES;
        }];
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        return executionTime;
    }
}


- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}


@end
