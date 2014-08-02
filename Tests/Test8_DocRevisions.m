//
// PerfTestScenario8.m
// Worker Bee
//
// Created by Ashvinder Singh on 2/13/14.
// Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import <malloc/malloc.h>
#import <CouchbaseLite/CBLJSON.h>
#import "Test8_DocRevisions.h"

@implementation Test8_DocRevisions

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    @autoreleasepool {
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
        NSNumber *flag = @YES;
        NSDictionary* props = @{@"data": str, @"toogle":flag};
        
        self.docs = [[NSMutableArray alloc] init];
        [self.database inTransaction:^BOOL{
            for (int j = 0; j < kNumberOfDocuments; j++) {
                @autoreleasepool {
                    CBLDocument* doc = [self.database createDocument];
                    [self.docs addObject:doc];
                    NSError* error;
                    if (![doc putProperties: props error: &error]) {
                        [self logFormat: @"!!! Failed to put property for data %@", props];
                        self.error = error;
                    }
                }
            }
            return YES;
        }];
    }
    
    @autoreleasepool {
        // Start measuring time from here
        NSDate *start = [NSDate date];
        
        [self.database inTransaction:^BOOL{
            for (CBLDocument *doc in self.docs) {
                @autoreleasepool {
                    // copy the document
                    NSMutableDictionary *contents = [doc.properties mutableCopy];
                    
                    // toggle value of check property
                    bool wasChecked = [[contents valueForKey: @"toggle"] boolValue];
                    [contents setObject: [NSNumber numberWithBool: !wasChecked] forKey: @"toggle"];
                    
                    // save the updated document
                    NSError* error;
                    if (![doc putProperties: contents error: &error]) {
                        [self logFormat: @"!!! Failed to Update doc"];
                        self.error = error;
                    }
                    if (self.error) {
                        [self logFormat:@"Got Error: %@",self.error];
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