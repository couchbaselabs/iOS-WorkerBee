//
//  Test24_PullReplication.h
//  Worker Bee
//
//  Created by Li Yang on 7/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchMultipleTest.h"

/*
 Test Definition: Test Pull replication
 */


@interface Test24_PullReplication : BeeCouchMultipleTest

@property  CBLReplication *pull;
@property  CBLReplication *push;


@end
