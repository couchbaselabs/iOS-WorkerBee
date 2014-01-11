//
//  TestListController.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "TestListController.h"
#import "AppDelegate.h"
#import "BeeTest.h"
#import "BeeTestController.h"
#import "SavedTestRun.h"
#import <CouchbaseLiteListener/CBLListener.h>


// Set this to a URL to a database to which saved tests should be uploaded.
//#define kUpstreamSavedTestDatabaseURL @"http://example.com/workerbee-tests"


#define kListenerPort 59840


@interface TestListController ()
- (void) updateSavedTestUI;
@end


@implementation TestListController
{
    NSMutableDictionary* _activeTestByClass;
    CBLListener* _listener;
}

static UIColor* kBGColor;

+ (void) initialize {
    if (self == [TestListController class]) {
        if (!kBGColor)
            kBGColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"double_lined.png"]];
    }
}

@synthesize testList = _testList, tableView = _tableView,
            savedRunCountLabel = _savedRunCountLabel, uploadButton = _uploadButton;

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

    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundColor: [UIColor clearColor]];
    [self.view setBackgroundColor:kBGColor];
    
    [_savedRunCountLabel setHidden: YES];
    [_uploadButton setHidden: YES];

    [self startListener];

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
    [self updateSavedTestUI];
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
    return YES;
}


- (void) updateSavedTestUI {
#ifdef kUpstreamSavedTestDatabaseURL
    NSString* text;
    int nSaved = [SavedTestRun savedTestCount];
    switch (nSaved) {
        case 0:
            text = @"no saved test runs";
            break;
        case 1:
            text = @"one saved test run";
            break;
        default:
            text = [NSString stringWithFormat: @"%u saved test runs", nSaved];
            break;
    }
    _savedRunCountLabel.text = text;
    _savedRunCountLabel.hidden = _uploadButton.hidden = (nSaved == 0);
#endif
}


- (void) startListener {
    CBLManager* manager = [CBLManager sharedInstance];
    _listener = [[CBLListener alloc] initWithManager: manager port: kListenerPort];
    [_listener setBonjourName: @"" type: @"_cbl._tcp."];
    NSString* message;
    NSError* error;
    if ([_listener start: &error]) {
        message = [NSString stringWithFormat: @"Listener starting on port %d...", _listener.port];
        [_listener addObserver: self forKeyPath: @"bonjourURL" options: 0 context: NULL];
    } else{  //FIX: Show alert
        message = [NSString stringWithFormat: @"Listener failed to start: %@", error.localizedDescription];
    }
    _listenerInfo.text = message;
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier];
        UISwitch* sw = [[UISwitch alloc] init];
        cell.accessoryView = sw;
        [sw addTarget: self action: @selector(startStopTest:) forControlEvents: UIControlEventValueChanged];
    }
    
    Class testClass = _testList[indexPath.row];
    BeeTest* existingTest = [self testForClass: testClass];
    cell.textLabel.text = [testClass displayName];
    UISwitch* sw = (UISwitch*)cell.accessoryView;
    sw.on = existingTest.running;
    sw.tag = indexPath.row;
    return cell;
}


#pragma mark - Table view delegate

- (BeeTest*) testForClass: (Class)testClass {
    return _activeTestByClass[[testClass testName]];
}

- (BeeTest*) makeTestForClass: (Class)testClass {
    BeeTest* test = [self testForClass: testClass];
    if (!test) {
        test = [[testClass alloc] init];
        if (test) {
            _activeTestByClass[[testClass testName]] = test;
            [test addObserver: self forKeyPath: @"running" options: 0 context: NULL];
        }
    }
    return test;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class testClass = _testList[indexPath.row];
    BeeTest* test = [self makeTestForClass: testClass];
    if (!test)
        return; // TODO: Show an alert
    BeeTestController *testController = [[BeeTestController alloc] initWithTest: test];
    [self.navigationController pushViewController:testController animated:YES];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object 
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if (object == _listener) {
        _listenerInfo.text = [NSString stringWithFormat: @"Listener available at %@",
                              _listener.URL];

    } else if ([object isKindOfClass: [BeeTest class]]) {
        // Test "running" state changed:
        BOOL running = [object running];
        Class testClass = [object class];
        NSUInteger index = [_testList indexOfObjectIdenticalTo: testClass];
        NSAssert(index != NSNotFound, @"Can't find %@", object);
        NSIndexPath* path = [NSIndexPath indexPathForRow: index inSection: 0];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath: path];
        UISwitch* sw = (UISwitch*)cell.accessoryView;
        [sw setOn: running animated: YES];
        if (!running)
            [self updateSavedTestUI];
    }
}

- (IBAction) startStopTest:(id)sender {
    Class testClass = _testList[[sender tag]];
    BeeTest* test = [self makeTestForClass: testClass];
    BOOL running = [sender isOn];
    NSLog(@"Setting %@ running=%i", test, running);
    if (!running)
        test.stoppedByUser = YES;
    test.running = running;
}

- (IBAction) uploadSavedRuns:(id)sender {
#ifdef kUpstreamSavedTestDatabaseURL
    NSURL* url = [NSURL URLWithString: kUpstreamSavedTestDatabaseURL];
    NSError* error;
    if ([SavedTestRun uploadAllTo: url error: &error])
        [self updateSavedTestUI];
    else {
        NSLog(@"ERROR: Upload failed: %@", error);
        NSString* message = [NSString stringWithFormat: @"Couldn't upload saved test results: %@."
                                                         "\n\nPlease try again later.",
                                                        error.localizedDescription];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Upload Failed"
                                                        message: message
                                                       delegate: nil
                                              cancelButtonTitle: @"Sorry"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
#endif
}

@end
