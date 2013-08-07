//
//  SavedTestRun.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/10/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "SavedTestRun.h"
#import "AppDelegate.h"
#import "BeeTest.h"


@implementation SavedTestRun


CBLDatabase* sDatabase;
NSUInteger sCount;


+ (CBLDatabase*) database {
    if (!sDatabase) {
        sDatabase = [[[CBLManager sharedInstance] createDatabaseNamed: @"workerbee-tests" error: NULL] retain];
        sCount = [sDatabase documentCount];
    }
    return sDatabase;
}

@dynamic device, serverVersion, testName, startTime, endTime, duration,
         stoppedByUser, status, error, log;

- (void) recordTest: (BeeTest*)test {
    UIDevice* deviceInfo = [UIDevice currentDevice];
    self.device = [NSDictionary dictionaryWithObjectsAndKeys:
                   deviceInfo.name, @"name",
                   deviceInfo.model, @"model",
                   deviceInfo.systemVersion, @"system",
                   deviceInfo.identifierForVendor.UUIDString, @"identifier",
                   [NSNumber numberWithInt: deviceInfo.batteryState], @"batteryState",
                   [NSNumber numberWithFloat: deviceInfo.batteryLevel], @"batteryLevel",
                   nil];
    self.serverVersion = CBLVersionString();
    self.testName = [[test class] testName];
    self.startTime = test.startTime;
    self.endTime = test.endTime;
    self.duration = [test.endTime timeIntervalSinceDate: test.startTime];
    if (test.stoppedByUser)
        self.stoppedByUser = YES;
    self.status = test.status;
    self.error = test.errorMessage;
    self.log = [test.messages componentsJoinedByString: @"\n"];
}

+ (SavedTestRun*) forTest: (BeeTest*)test {
    SavedTestRun* instance = [[self alloc] initWithNewDocumentInDatabase: [self database]];
    [instance recordTest: test];
    ++sCount;
    return [instance autorelease];
}

+ (NSUInteger) savedTestCount {
    if (!sDatabase)
        [self database];    // trigger connection
    return sCount;
}

+ (BOOL) uploadAllTo: (NSURL*)upstreamURL error: (NSError**)outError {
    CBLReplication* repl = [[self database] pushToURL: upstreamURL];
    while (repl.running) {
        NSLog(@"Waiting for replication to finish...");
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate: [NSDate distantFuture]];
    }
    
    *outError = repl.error;
    NSLog(@"...Replication finished. Error = %@", repl.error);
    if (*outError)
        return NO;
    
    // After a successful push, delete the database because we don't need to keep the test
    // results around anymore. (Just deleting the documents would leave tombstones behind,
    // which would propagate to the server on the next push and delete them there too. Bad.)
    [sDatabase deleteDatabase: NULL];
    [sDatabase release];
    sDatabase = nil;
    sCount = 0;
    return YES;
}

@end
