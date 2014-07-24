//
// Test13_ReplicateWithAttachment.h
// Worker Bee
//
// Created by Ashvinder Singh on 4/23/14.
// Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchMultipleTest.h"

@interface Test13_ReplicateWithAttachment : BeeCouchMultipleTest

@property CBLReplication *push;

extern NSString * const syncGatewayURL;

@end