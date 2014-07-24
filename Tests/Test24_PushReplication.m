//
//  PerfTestScenario6.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/12/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import <malloc/malloc.h>
#import "Test24_PushReplication.h"
#import <CouchbaseLite/CouchbaseLite.h>

@implementation Test24_PushReplication
{
    bool replicationRunning;
}

- (void) pushReplicationChanged: (NSNotificationCenter*)n {
   // Uncomment the following line to see the progress of replication
   [self logFormat: @"Completed %d Out of total %d",self.push.completedChangesCount,self.push.changesCount];
    
   if (self.push.status == kCBLReplicationStopped) {
       // If do not see this line, it means there is no error
       if (self.push.lastError)
          [self logSummary:[NSString stringWithFormat:
                            @"*** Replication Stopped and error found - %@", self.push.lastError]];
       replicationRunning = NO;
   }
}

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    NSDictionary* environmentConfig = [[BeeTest config] objectForKey:@"environment"];
    NSString* syncGatewayIp = [environmentConfig  objectForKey:@"sync_gateway_ip"];
    NSString* syncGatewayPort = [environmentConfig  objectForKey:@"sync_gateway_port"];
    NSString* syncGatewayDb = [environmentConfig  objectForKey:@"sync_gateway_db"];
    NSString* syncGatewayUrl = [NSString  stringWithFormat:@"http://%@:%@/%@",
                      syncGatewayIp, syncGatewayPort, syncGatewayDb];
    [self logFormat: @"Starting Test %@ - Sync_gateway %@", [self class], syncGatewayUrl];
    
    @autoreleasepool {
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
        NSDictionary* props = @{@"k": str};
        
        [self.database inTransaction:^BOOL{
            for (int j = 0; j < kNumberOfDocuments; j++) {
                @autoreleasepool {
                    CBLDocument* doc = [self.database createDocument];
                    NSError* error;
                    if (![doc putProperties: props error: &error]) {
                        [self logFormat: @"!!! Failed to create doc %@", props];
                        self.error = error;
                    }
                }
            }
            return YES;
        }];
    }
    
    @autoreleasepool {
        NSURL *syncGateway  = [NSURL URLWithString:syncGatewayUrl];
        self.push = [self.database createPushReplication: syncGateway];
        [self logFormat: @"Starting Push Replication"];
        
        // Start measuring time from here
        NSDate* start = [NSDate date];
        [self.push start];
        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        [nctr addObserver: self selector: @selector(pushReplicationChanged:)
                     name: kCBLReplicationChangeNotification object: self.push];

        replicationRunning = YES;
        while (replicationRunning) {
            [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                     beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
        }

        NSDate *methodFinish = [NSDate date];
        [self logFormat: @"Push Replication Stopped"];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        [self deleteDatabase];
        sleep(20);
        return executionTime;
    }
}


@end
