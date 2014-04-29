//
//  Test13_ReplicateWithAttachment.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 4/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test13_PushReplicateWithAttachment.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>


#define kNumberOfDocuments 1
// size in bytes
#define kSizeofAttachment 100000000

NSString * const syncGatewayURL = @"http://10.17.33.142:4985/sync_gateway1";


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
    
    NSString *cachesFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [cachesFolder stringByAppendingPathComponent:@"testfile"];
    _fileurl = [NSURL fileURLWithPath:file];
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:file contents:nil attributes:nil];
    
    [self logFormat: @"Created file at %@", _fileurl];
    if (!success) {
        [self logFormat: @"Failed to create file at %@", file];
        self.running = NO;
    }
    
    NSError *error = nil;
    // Append data to the file in increments of 1% of totalsize of attachment
    for (int i = 0; i <= kSizeofAttachment; i += 1 + kSizeofAttachment / 100) {
        NSMutableData *data = [NSMutableData dataWithLength:i];
        [data writeToURL:_fileurl options:NSDataWritingAtomic error:&error];
    }
    
    NSFileManager *man = [NSFileManager defaultManager];
    NSDictionary *attrs = [man attributesOfItemAtPath:file error: NULL];
    double result = [attrs fileSize];
    
    [self logFormat: @"created file size %f", result];
    
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
                    [self logFormat: @"!!! Failed to attach"];
                    self.error = error;
                }
            }
        }
        return YES;
    }];
    
    
    NSURL *syncGateway  = [NSURL URLWithString:syncGatewayURL];
    
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
