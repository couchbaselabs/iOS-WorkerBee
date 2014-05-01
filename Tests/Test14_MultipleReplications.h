//
//  Test14_MultipleReplications.h
//  Worker Bee
//
//  Created by Ashvinder Singh on 4/24/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"

/*
 Test Definition: This test creates multiple pairs (push and pull) replications and prints the total time it took to complete all replication operations.  
 */

@interface Test14_MultipleReplications : BeeCouchTest

extern NSString * const syncGateways[];

@end
