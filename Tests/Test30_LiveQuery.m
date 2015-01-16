//
//  Test28_ReduceQuery2.m
//  Worker Bee
//
//  Created by Li Yang on 9/3/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test30_LiveQuery.h"

#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLView (Internal)
- (int) updateIndex;
@end

@implementation Test30_LiveQuery
{
    CBLLiveQuery *liveQuery;
    bool liveQueryRunning;
    int observeCallCount;
    int expectedObserveCallCount;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == liveQuery) {
        CBLQueryEnumerator* rowEnum = liveQuery.rows;
        [self logFormat: @"LiveQuery observer got %d rows", rowEnum.count];
        if (rowEnum.count == expectedObserveCallCount) {
            [self logFormat: @" LiveQuery observer got all %d rows", rowEnum.count];
            liveQueryRunning = NO;
        }
    }
}

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        NSDate *start;
        NSTimeInterval executionTimeTotal;
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
        observeCallCount = 0;
        expectedObserveCallCount = kNumberOfDocuments;

        @autoreleasepool {
            // Define view
            CBLView* view = [self.database viewNamed: @"vacant"];
            [view setMapBlock: MAPBLOCK({
                id apt = [doc objectForKey: @"apt"];
                id name = [doc objectForKey: @"name"];
                if (apt && name) emit(name, apt);
            }) reduceBlock: REDUCEBLOCK({
                return @([values count]);
            }) version: @"3"];

            [view updateIndex];

            // query
            CBLQuery* query = [[self.database viewNamed: @"vacant"] createQuery];
            query.mapOnly = YES;  //Do not put this line after liveQuery, otherwise it is treated as reduce query
            liveQuery = query.asLiveQuery;
            [liveQuery addObserver: self forKeyPath: @"rows" options: 0 context: NULL];
            [liveQuery start];

            // Start measuring time
            start = [NSDate date];

            // Create docs
            [self.database inTransaction:^BOOL{
                for (int i = 0; i < kNumberOfDocuments; i++) {
                    @autoreleasepool {
                        NSUInteger r = arc4random_uniform(kNumberOfDocuments-1) + 1;
                        NSString* name = [NSString stringWithFormat:@"%@%@", @"n", @(r)];
                        bool vacant = (i+2) % 2 ? 1 : 0;
                        NSDictionary* props = @{@"name":name,
                                                @"apt": [NSString stringWithFormat:@"%@%@", str, @(i)],
                                                @"vacant":@(vacant)};
                        CBLDocument* doc = [self.database createDocument];
                        NSError* error;
                        if (![doc putProperties: props error: &error]) {
                            [self logFormat: @"!!! Failed to create doc %@", props];
                            self.error = error;
                            return NO;
                        }
                    }
                }
                return YES;
            }];

            liveQueryRunning = YES;
            while (liveQueryRunning) {
                [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                         beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
            }
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;

            [liveQuery stop];
            [liveQuery removeObserver:self forKeyPath:@"rows"];
            [self deleteDatabase];
            sleep(10);
            return executionTime;
        }
        return executionTimeTotal;
    }
}

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 0.001;
}

@end