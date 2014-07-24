//
//  PerfTestScenario7.h
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/13/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchMultipleTest.h"

/*
 Test Definition: Test Pull replication
 */


@interface Test7_PullReplication : BeeCouchMultipleTest

@property  CBLReplication *pull;
@property  CBLReplication *push;


@end
