//
//  BeeCouchMultipleTest.h
//  Worker Bee
//
//  Created by Li Yang on 7/17/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchTest.h"

@interface BeeCouchMultipleTest : BeeCouchTest

- (void) runMultiple;
- (double) runOne:(int)numberOfDocuments sizeOfDocuments:(int)sizeOfDocuments;
- (void)logSummary:(NSString *)str;
- (void)logToFile:(NSString *)str;
 
@end
