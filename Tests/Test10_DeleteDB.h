//
//  PerfTestScenario10.h
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/14/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchMultipleTest.h"

/*
 Test Definition: Test how much time it takes to delete a database
 */


@interface Test10_DeleteDB : BeeCouchMultipleTest

@property NSString *dbname;

@end
