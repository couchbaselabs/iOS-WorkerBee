//
//  Test13_ReplicateWithAttachment.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 4/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test13_ReplicateWithAttachment.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>


#define kNumberOfDocuments 2
// size in bytes
#define kSizeofAttachment 100


@implementation Test13_ReplicateWithAttachment
{
    NSDate* _pushStartTime;
    NSURL* _fileurl;
}


- (void) replicationChanged: (NSNotificationCenter*)n {
    
    
    [self logFormat: @"Change in status"];
    
    unsigned completed = self.push.completedChangesCount;
    unsigned total = self.push.changesCount;
    
    [self logFormat: @"Completed %d Out of total %d",completed,total];
    
    if (self.push.status == kCBLReplicationStopped && !self.push.lastError) {
        [self logFormat: @"Replication Stopped and No Error Found"];
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:_pushStartTime];
        [self logFormat:@"Total Time Taken: %f",executionTime];
        [self logFormat: @"Completed %d Out of total %d",completed,total];
    }
    
    if (self.push.status == kCBLReplicationStopped) {
        [self logFormat: @"Replication Stopped"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        BOOL success = [fileManager removeItemAtURL:_fileurl error:&error];
        
        if (!success) {
            [self logFormat: @"Failed to delete test file"];
        }
        self.running = NO;
    }

}



- (void) setUp {
    [super setUp];
    
    NSMutableData *data = [NSMutableData dataWithLength:kSizeofAttachment];
    
    NSString *cachesFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [cachesFolder stringByAppendingPathComponent:@"testfile"];
    _fileurl = [NSURL fileURLWithPath:file];
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:file contents:data attributes:nil];
    
    [self logFormat: @"Created file at %@", _fileurl];
    if (!success) {
        [self logFormat: @"Failed to create file at %@", file];
        self.running = NO;
    }
    
    [self.database inTransaction:^BOOL{
        for (int j = 0; j < kNumberOfDocuments; j++) {
            @autoreleasepool {
                CBLDocument* doc = [self.database createDocument];
                CBLUnsavedRevision* rev = doc.newRevision;
                NSString *key = [NSString stringWithFormat:@"%d",j];
                [rev setAttachmentNamed:key withContentType:@"image/jpg" contentURL:_fileurl];
                
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
    
    
    NSURL *syncGateway  = [NSURL URLWithString:@"http://10.0.1.13:4985/sync_gateway"];
    
    self.push = [self.database createPushReplication: syncGateway];
    [self logFormat: @"Start Replication: Push"];
    
    // Start measuring time from here
    _pushStartTime = [NSDate date];
    
    [self.push start];
    
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver: self selector: @selector(replicationChanged:)
                 name: kCBLReplicationChangeNotification object: self.push];
    
}


@end
