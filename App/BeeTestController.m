//
//  BeeTestController.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTestController.h"
#import "BeeTest.h"
#import "SavedTestRun.h"


@interface BeeTestController () <BeeTestDelegate>
- (void) displayMessages;
- (void) scrollToEnd;
- (void) showStatus;
@end


@implementation BeeTestController

@synthesize test = _test, onOffSwitch = _onOffSwitch, activityIndicator = _activityIndicator, transcript = _transcript, statusLabel = _statusLabel;

- (id) initWithTest: (BeeTest*)test {
    self = [super initWithNibName: @"BeeTestController" bundle: nil];
    if (self) {
        _test = test;
        _test.delegate = self;
        [_test addObserver: self forKeyPath: @"status" options: 0 context: NULL];
        [_test addObserver: self forKeyPath: @"error" options: 0 context: NULL];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    NSLog(@"Receving a memory warning");
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [_test removeObserver: self forKeyPath: @"status"];
    [_test removeObserver: self forKeyPath: @"error"];
    _test.delegate = nil;
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [[_test class] displayName];
    
    static UIColor* sBackground;
    if (!sBackground) {
        UIImage* tile = [UIImage imageNamed: @"little_pluses.png"];
        sBackground = [UIColor colorWithPatternImage: tile];
    }
    self.view.backgroundColor = sBackground;
    
    [_onOffSwitch removeFromSuperview];
    UIBarButtonItem* rightItem = [[UIBarButtonItem alloc] initWithCustomView: _onOffSwitch];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self beeTest: _test isRunning: _test.running];
    [self showStatus];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark - Transcript

- (void) displayMessages {
    _transcript.text = [_test.messages componentsJoinedByString: @"\n"];
}

- (void) scrollToEnd {
    [_transcript scrollRangeToVisible: NSMakeRange(_transcript.text.length-1, 1)];
}

- (void) beeTest: (BeeTest*)test loggedMessage: (NSString*)message {
    BOOL scrollToEnd = !_transcript.tracking
            && CGRectGetMaxY(_transcript.bounds) >= _transcript.contentSize.height - 20;
    [self displayMessages];
    
    if (scrollToEnd)
        [self scrollToEnd];
    else
        [_transcript flashScrollIndicators];
}

#pragma mark - Starting / stopping

- (void) beeTest: (BeeTest*)test isRunning: (BOOL)running {
    [_onOffSwitch setOn: running];
    if (_test.running)
        [_activityIndicator startAnimating];
    else
        [_activityIndicator stopAnimating];
    [self displayMessages];
}

- (IBAction) startStopTest:(id)sender {
    if (![sender isOn])
        _test.stoppedByUser = YES;
    _test.running = [sender isOn];
}

- (void) showStatus {
    NSString* status;
    UIColor* color;
    if (_test.error) {
        status = _test.errorMessage;
        color = [UIColor redColor];
    } else {
        status = _test.status;
        color = [UIColor blackColor];
    }
    _statusLabel.text = status;
    _statusLabel.textColor = color;
    
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if ([keyPath isEqualToString: @"status"] || [keyPath isEqualToString: @"error"])
        [self showStatus];
}

@end
