//
//  TestListController.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "TestListController.h"
#import "BeeTest.h"
#import "BeeTestController.h"


@implementation TestListController
{
    NSMutableDictionary* _activeTestByClass;
}

static UIColor* kBGColor;

+ (void) initialize {
    if (self == [TestListController class]) {
        if (!kBGColor)
            kBGColor = [[UIColor colorWithPatternImage: [UIImage imageNamed:@"double_lined.png"]] 
                        retain];
    }
}

@synthesize testList = _testList;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [_testList release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!_testList) {
        _testList = [[BeeTest allTestClasses] copy];
        _activeTestByClass = [[NSMutableDictionary alloc] init];
    }

    // Use short name "Tests" in the back button leading to this view
    UIBarButtonItem* backItem = [[UIBarButtonItem alloc] init];
    backItem.title = @"Tests";
    self.navigationItem.backBarButtonItem = backItem;
    [backItem release];

    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundColor:kBGColor];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSAssert(_testList, @"didn't load test list");
    return _testList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    Class testClass = [_testList objectAtIndex: indexPath.row];
    cell.textLabel.text = [testClass displayName];
    
    return cell;
}


#pragma mark - Table view delegate

- (BeeTest*) testForClass: (Class)testClass {
    NSString* key = NSStringFromClass(testClass);
    BeeTest* test = [_activeTestByClass objectForKey: key];
    if (!test) {
        test = [[testClass alloc] init];
        if (test)
            [_activeTestByClass setObject: test forKey: key];
    }
    return test;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class testClass = [_testList objectAtIndex: indexPath.row];
    BeeTest* test = [self testForClass: testClass];
    if (!test)
        return; // TODO: Show an alert
    BeeTestController *testController = [[BeeTestController alloc] initWithTest: test];
    [self.navigationController pushViewController:testController animated:YES];
    [testController release];
}

@end
