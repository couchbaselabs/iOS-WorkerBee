//
//  TestListController.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BeeTest;

@interface TestListController : UITableViewController

@property (readonly) NSArray* testList;
- (BeeTest*) testForClass: (Class)testClass;
- (BeeTest*) makeTestForClass: (Class)testClass;

@end
