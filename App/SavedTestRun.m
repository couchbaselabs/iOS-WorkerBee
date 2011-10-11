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

CouchDatabase* sDatabase;

+ (CouchDatabase*) database {
    if (!sDatabase) {
        NSURL* serverURL = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).serverURL;
        NSAssert(serverURL, @"No server URL");
        CouchServer* server = [[CouchServer alloc] initWithURL: serverURL];
        sDatabase = [[server databaseNamed: @"workerbee-tests"] retain];
        [server release];

        RESTOperation* op = [sDatabase create];
        if (![op wait]) {
            if(op.httpStatus != 412)
                NSAssert(NO, @"Error creating db: %@", op.error);   // TODO: Real alert
        }
    }
    return sDatabase;
}

@dynamic device, testName, startTime, endTime, stoppedByUser, status, error, log;

- (void) recordTest: (BeeTest*)test {
    UIDevice* deviceInfo = [UIDevice currentDevice];
    self.device = [NSDictionary dictionaryWithObjectsAndKeys:
                   deviceInfo.name, @"name",
                   deviceInfo.model, @"model",
                   deviceInfo.systemVersion, @"system",
                   deviceInfo.uniqueIdentifier, @"UDID",
                   [NSNumber numberWithInt: deviceInfo.batteryState], @"batteryState",
                   [NSNumber numberWithFloat: deviceInfo.batteryLevel], @"batteryLevel",
                   nil];
    self.testName = [[test class] testName];
    self.startTime = test.startTime;
    self.endTime = test.endTime;
    if (test.stoppedByUser)
        self.stoppedByUser = YES;
    self.status = test.status;
    self.error = test.errorMessage;
    self.log = [test.messages componentsJoinedByString: @"\n"];
}

+ (SavedTestRun*) forTest: (BeeTest*)test {
    SavedTestRun* instance = [[self alloc] initWithNewDocumentInDatabase: [self database]];
    [instance recordTest: test];
    return [instance autorelease];
}

+ (BOOL) uploadAllTo: (NSURL*)upstreamURL error: (NSError**)outError {
    CouchReplication* repl = [[self database] pushToDatabaseAtURL: upstreamURL options: 0];
    RESTOperation* op = [repl start];
    if (![op wait]) {
        if (outError) *outError = op.error;
        return NO;
    }
    // After a successful push, delete the database because we don't need to keep the test
    // results around anymore. (Just deleting the documents would leave tombstones behind,
    // which would propagate to the server on the next push and delete them there too. Bad.)
    [[sDatabase DELETE] wait];
    [sDatabase release];
    sDatabase = nil;
    return YES;
}

@end
