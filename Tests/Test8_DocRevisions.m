//
//  PerfTestScenario8.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/13/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import <malloc/malloc.h>
#import <CouchbaseLite/CBLJSON.h>
#import "Test8_DocRevisions.h"

#define kNumberOfDocuments 1000
#define kNumberOfUpdates 100

@implementation Test8_DocRevisions

- (void) heartbeat {
    [self logFormat: @"Starting Test"];
    
    // Start measuring time from here
     NSDate *start = [NSDate date];

    
    for (int i = 0; i < kNumberOfUpdates; i++) {
        NSDate *inter_start = [NSDate date];
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
        NSDate *interTime = [NSDate date];
        NSTimeInterval executionTime = [interTime timeIntervalSinceDate:inter_start];
        [self logFormat:@"Time for 1000 docs: %f, count: %d",executionTime,i];
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    [self logFormat:@"Total Time Taken: %f",executionTime];
    self.running = NO;
}


- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
    
    NSMutableString *str = [[NSMutableString alloc] init];
    [str appendString:@"1"];
    
    
    NSUInteger bytes = [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    [self logFormat:@"%lu bytes", (unsigned long)bytes];
    
    NSNumber *flag = @YES;
    
    NSDictionary* props = @{@"toogle":flag};
    
    self.docs = [[NSMutableArray alloc] init];
    
    [self.database inTransaction:^BOOL{
        for (int j = 0; j < kNumberOfDocuments; j++) {
            
            @autoreleasepool {
        
                CBLDocument* doc = [self.database createDocument];
                
                [self.docs addObject:doc];
                
                NSError* error;
                
                if (![doc putProperties: props error: &error]) {
                    [self logFormat: @"!!! Failed to create doc %@", props];
                    self.error = error;
                }
            }
        }
        [self logFormat: @"Created %d documents",kNumberOfDocuments];
        return YES;
    }];
    
}

@end
