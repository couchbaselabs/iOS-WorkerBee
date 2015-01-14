//
//  Test21_Index.m
//  Worker Bee
//
//  Created by Li Yang on 7/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test21_Index.h"
#import <malloc/malloc.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLView (Internal)
- (int) updateIndex;
@end


@implementation Test21_Index


- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        [self.database inTransaction:^BOOL{
            // The kSizeofDocument affect overall size of doc, but not key size
            NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
            memset(utf8.mutableBytes, '1', utf8.length);
            NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];

            for (int i = 0; i < kNumberOfDocuments; i++) {
                @autoreleasepool {
                    NSString* name = [NSString stringWithFormat:@"%@%@", @"n", @(i)];
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
    }

    @autoreleasepool {

        CBLView* view = [self.database viewNamed: @"vacant"];
        
        [view setMapBlock: MAPBLOCK({
            id v = [doc objectForKey: @"vacant"];
            id name = [doc objectForKey: @"name"];
            if (v && name) emit(name, v);
        }) reduceBlock: REDUCEBLOCK({return @(values.count);})
                  version: @"3"];

        NSDate *start = [NSDate date];
        
        [view updateIndex];
        
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        return executionTime;
    }
    
}

/*
 Create a fake database modeling an apartment complex have the following fields:
 Name:
 Apt#:
 Phone:
 Vacant: YES / NO
 */

- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 0.001;
}



@end