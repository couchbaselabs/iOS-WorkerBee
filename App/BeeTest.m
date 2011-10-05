//
//  BeeTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTest.h"
#import <objc/runtime.h>


#define kMaxMessageCount 100


@interface BeeTest ()
{
    BOOL _running;
    NSMutableArray* _messages;
    NSTimer* _heartbeat;
}
@property (readwrite, retain) NSDate* startTime;
@property (readwrite, retain) NSDate* endTime;
@property (retain) NSString* lastTimestamp;
@end


@implementation BeeTest


+ (BOOL) isAbstractTest {
    return self == [BeeTest class];
}


+ (NSArray*) allTestClasses {
    static NSArray* sAllTestClasses;
    if (!sAllTestClasses) {
        NSMutableArray* testClasses = [NSMutableArray array];
        
        int numClasses = objc_getClassList(NULL, 0);
        Class* classes = malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i< numClasses; i++) {
            Class c = classes[i];
            if (class_getClassMethod(c, @selector(isSubclassOfClass:)) 
                    && [c isSubclassOfClass: self]
                    && ![c isAbstractTest]) {
                NSLog(@"BeeTets: Found test class %@", classes[i]);
                [testClasses addObject: classes[i]];
            }
        }
        free(classes);
        [testClasses sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [NSStringFromClass(obj1) caseInsensitiveCompare: NSStringFromClass(obj2)];
        }];
        sAllTestClasses = [testClasses copy];
    }
    return sAllTestClasses;
}

+ (NSString*) displayName {
    NSString* name = NSStringFromClass(self);
    if ([name hasSuffix: @"Test"])
        name = [name substringToIndex: name.length - 4];
    return name;
}


@synthesize delegate=_delegate, status = _status, startTime = _startTime, endTime = _endTime, error = _error, messages = _messages, lastTimestamp = _lastTimestamp;


- (id)init {
    self = [super init];
    if (self) {
        _messages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_messages release];
    [_lastTimestamp release];
    [_startTime release];
    [_endTime release];
    [_error release];
    [super dealloc];
}


- (NSError*) error {
    return _error;
}

- (void) setError: (NSError*)error {
    if (error != _error) {
        [_error release];
        _error = [error retain];
        if (error) {
            // Log the error and stop the test:
            NSString* message = [error.domain isEqualToString: @"BeeTest"] ? self.errorMessage
                                                                           : error.description;
            [self logFormat: @"ERROR: %@", message];
            self.running = NO;
        }
    }
}


- (void) setErrorMessage:(NSString *)errorMessage {
    if (errorMessage) {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              errorMessage, NSLocalizedDescriptionKey, nil];
        self.error = [NSError errorWithDomain: @"BeeTest" code: 1 userInfo: info];
    } else {
        self.error = nil;
    }
}

- (NSString*) errorMessage {
    return self.error.localizedDescription;
}


- (BOOL) running {
    return _running;
}

- (void) setRunning:(BOOL)run {
    if (run != _running) {
        _running = run;
        if (run) {
            self.startTime = [NSDate date];
            self.endTime = nil;
            self.error = nil;
            self.status = nil;
            [self clearMessages];
        } else {
            self.endTime = [NSDate date];
            self.status = nil;
        }
        [self addTimestamp: (run ? @"STARTED" : @"STOPPED")];
        [_delegate beeTest: self isRunning: _running];
        
        if (run)
            [self setUp];
        else
            [self tearDown];
    }
}

- (NSString*) shortTimestamp {
    static NSDateFormatter* sFormat;
    if (!sFormat) {
        sFormat = [[NSDateFormatter alloc] init];
        sFormat.dateStyle = NSDateFormatterShortStyle;
        sFormat.timeStyle = NSDateFormatterShortStyle;
    }
    return [sFormat stringFromDate: [NSDate date]];
}

- (NSString*) fullTimestamp {
    static NSDateFormatter* sFormat;
    if (!sFormat) {
        sFormat = [[NSDateFormatter alloc] init];
        sFormat.dateStyle = NSDateFormatterShortStyle;
        sFormat.timeStyle = NSDateFormatterMediumStyle;
    }
    return [sFormat stringFromDate: [NSDate date]];
}

- (BOOL) addTimestamp: (NSString*)message {
    // Check whether short timestamp has changed (it only shows the minute):
    NSString* shortTimestamp = self.shortTimestamp;
    if (!message && [shortTimestamp isEqualToString: _lastTimestamp])
        return NO;
    self.lastTimestamp = shortTimestamp;
    
    // But display the full timestamp, which shows seconds:
    message = [NSString stringWithFormat: @"---- %@ %@",
               self.fullTimestamp, (message ? message : @"")];
    [_messages addObject: message];
    return YES;
}

- (void) logMessage:(NSString *)message {
    [self addTimestamp: nil];
    [_messages addObject: message];
    if (_messages.count > kMaxMessageCount)
        [_messages removeObjectAtIndex: 0];
    [_delegate beeTest: self loggedMessage: message];
}

- (void) logFormat: (NSString*)format, ... {
    va_list args;
    va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat: format arguments: args];
    va_end(args);
    [self logMessage: message];
    [message release];
}

- (void) clearMessages {
    [_messages removeAllObjects];
    self.lastTimestamp = nil;
}


- (void) setUp {
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver: self
             selector: @selector(applicationDidEnterBackground:)
                 name: UIApplicationDidEnterBackgroundNotification
               object: nil];
    [nctr addObserver: self
             selector: @selector(applicationWillEnterForeground:)
                 name: UIApplicationWillEnterForegroundNotification
               object: nil];
}

- (void) tearDown {
    self.heartbeatInterval = 0.0;
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr removeObserver: self
                    name:UIApplicationDidEnterBackgroundNotification
                  object: nil];
    [nctr removeObserver: self
                    name:UIApplicationWillEnterForegroundNotification
                  object: nil];
}


- (void)applicationDidEnterBackground: (NSNotification*)notification
{
    [self addTimestamp: @"BACKGROUND"];
}


- (void)applicationWillEnterForeground: (NSNotification*)notification
{
    [self addTimestamp: @"FOREGROUND"];
}


- (NSTimeInterval) heartbeatInterval {
    return _heartbeat ? [_heartbeat timeInterval] : 0.0;
}

- (void) setHeartbeatInterval: (NSTimeInterval)interval {
    [_heartbeat invalidate];
    [_heartbeat release];
    if (interval > 0) {
        _heartbeat = [[NSTimer scheduledTimerWithTimeInterval: interval
                                               target: self
                                             selector: @selector(heartbeat)
                                             userInfo: NULL
                                              repeats: YES] retain];
    } else {
        _heartbeat = nil;
    }
}


- (void) heartbeat {
}


@end
