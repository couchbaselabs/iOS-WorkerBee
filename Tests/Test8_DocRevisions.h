//
//  PerfTestScenario8.h
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/13/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchMultipleTest.h"

/*
 Test Definition: Test Doc revision performance by updating a value n times
 */


@interface Test8_DocRevisions : BeeCouchMultipleTest

@property NSMutableArray *docs;

@end
