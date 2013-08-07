//
//  SavedTestRun.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/10/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>
@class BeeTest;


@interface SavedTestRun : CBLModel

+ (SavedTestRun*) forTest: (BeeTest*)test;

+ (NSUInteger) savedTestCount;
+ (BOOL) uploadAllTo: (NSURL*)upstreamURL error: (NSError**)outError;

@property (copy) NSDictionary* device;
@property (copy) NSString* serverVersion;
@property (copy) NSString* testName;
@property (retain) NSDate* startTime, *endTime;
@property NSTimeInterval duration;
@property BOOL stoppedByUser;
@property (copy) NSString* status;
@property (copy) NSString* error;
@property (copy) NSString* log;

@end
