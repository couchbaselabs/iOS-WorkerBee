//
//  BeeTestController.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTestController.h"
#import "BeeTest.h"


@interface BeeTestController () <BeeTestDelegate>
- (void) displayMessages;
- (void) scrollToEnd;
@end


@implementation BeeTestController

@synthesize test = _test, onOffSwitch = _onOffSwitch, activityIndicator = _activityIndicator, transcript = _transcript;

- (id) initWithTest: (BeeTest*)test {
    self = [super initWithNibName: @"BeeTestController" bundle: nil];
    if (self) {
        _test = [test retain];
        _test.delegate = self;
    }
    return self;
}

- (void)dealloc {
    _test.delegate = nil;
    [_test release];
    [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [[_test class] displayName];
    
    static UIColor* sBackground;
    if (!sBackground) {
        UIImage* tile = [UIImage imageNamed: @"little_pluses.png"];
        sBackground = [[UIColor colorWithPatternImage: tile] retain];
    }
    self.view.backgroundColor = sBackground;
    
    [self beeTest: _test isRunning: _test.running];
    [self scrollToEnd];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Transcript

- (void) displayMessages {
    _transcript.text = [_test.messages componentsJoinedByString: @"\n"];
}

- (void) scrollToEnd {
    [_transcript scrollRangeToVisible: NSMakeRange(_transcript.text.length-1, 1)];
    NSLog(@"scrollToEnd: length=%u", _transcript.text.length);
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
    _test.running = [sender isOn];
}

@end
