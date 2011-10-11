//
//  SavedTestRun.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/10/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>
@class BeeTest;


@interface SavedTestRun : CouchModel

+ (SavedTestRun*) forTest: (BeeTest*)test;

+ (NSString*) serverVersion;
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
