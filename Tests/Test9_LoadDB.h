//
//  PerfTestScenario9.h
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/14/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"

/*
 Test Definition: Test how much time it takes to load a database
 */


@interface Test9_LoadDB : BeeCouchTest

@property  CBLManager* mymanager;

@property (readonly) CBLDatabase* database;

@property NSString *dbname;

@end
