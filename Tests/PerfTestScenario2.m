//
//  PerfTestScenario2.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/7/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import <malloc/malloc.h>
#import "PerfTestScenario2.h"
#import <CouchbaseLite/CouchbaseLite.h>

// In Bytes
//#define kSizeOfAttachment  500
//#define kSizeOfAttachment  1000
//#define kSizeOfAttachment  10000
#define kSizeOfAttachment  100000
//#define kSizeOfAttachment  1000000
//#define kSizeOfAttachment  10000000
//#define kSizeOfAttachment  50000000


@implementation PerfTestScenario2


- (void) heartbeat {
    
    //int aNumberOfDocs[6] = {10,100,1000,10000,50000,100000};
    //int aNumberOfDocs[3] = {10,100,1000};
    int aNumberOfDocs[1] = {10000};
    
    NSMutableString *str = [NSMutableString stringWithCapacity:100];
    for (int i = 0; i< kSizeOfAttachment; i++) {
        [str appendString:@"1"];
    }
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    for (int j = 0 ; j < (sizeof aNumberOfDocs) / (sizeof aNumberOfDocs[0]); j++ ) {
        //[self logFormat: @"%d",aNumberOfDocs[j]];
        int docs = aNumberOfDocs[j];
        [self logFormat: @"Starting Test"];
        NSDate *start = [NSDate date];
        [self.database inTransaction:^BOOL{
            for (int i = 0; i< docs ; i++) {
                NSString *key = [NSString stringWithFormat:@"%d",i];
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
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
        [self logFormat: @"Attachment size:%u", data.length];
        [self logFormat:@"Documents with attachment: %d",docs];
        [self logFormat:@"Total Time Taken: %f",executionTime];
    }

    self.running = NO;
    
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}


@end
