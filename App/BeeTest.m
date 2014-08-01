//
//  BeeTest.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "BeeTest.h"
#import "SavedTestRun.h"
#import <CouchbaseLite/CBLJSON.h>
#import <objc/runtime.h>


/** Number of most-recent messages to keep in the messages property */
#define kMaxMessageCount 100


@interface BeeTest ()
{
    BOOL _running;
    NSOutputStream* _output;
    NSMutableArray* _messages;
    NSTimer* _heartbeat;
}
@property (readwrite, strong) NSDate* startTime;
@property (readwrite, strong) NSDate* endTime;
@property (strong) NSString* lastTimestamp;
- (void) openOutput;
- (void) closeOutput;
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
        Class* classes = (Class*)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i< numClasses; i++) {
            Class c = classes[i];
            if (class_getClassMethod(c, @selector(isSubclassOfClass:)) 
                    && [c isSubclassOfClass: self]
                    && ![c isAbstractTest]) {
                NSLog(@"BeeTest: Found test class %@", classes[i]);
                [testClasses addObject: classes[i]];
            }
        }
        free(classes);
        [testClasses sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj1 displayName] caseInsensitiveCompare: [obj2 displayName]];
        }];
        sAllTestClasses = [testClasses copy];
    }
    return sAllTestClasses;
}

+ (NSString*) testName {
    return NSStringFromClass(self);
}

+ (NSString*) displayName {
    NSString* name = [self testName];
    if ([name hasSuffix: @"Test"])
        name = [name substringToIndex: name.length - 4];
    return name;
}

static NSDictionary* config;
+ (void) setConfig: (NSDictionary*)config_in {
    config = config_in;
}

+ (NSDictionary*) config {
    return config;
}


@synthesize delegate=_delegate, status = _status, startTime = _startTime, endTime = _endTime,
            stoppedByUser = _stoppedByUser, error = _error, messages = _messages,
            lastTimestamp = _lastTimestamp;


- (id)init {
    self = [super init];
    if (self) {
        _messages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_output close];
}


- (NSError*) error {
    return _error;
}

- (void) setError: (NSError*)error {
    if (error != _error) {
        _error = error;
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
        NSDictionary* info = @{NSLocalizedDescriptionKey: errorMessage};
        self.error = [NSError errorWithDomain: @"BeeTest" code: 1 userInfo: info];
    } else {
        self.error = nil;
    }
}

- (NSString*) errorMessage {
    return self.error.localizedDescription;
}


#pragma mark - START / STOP:


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
            [self openOutput];
        } else {
            self.endTime = [NSDate date];
            self.status = nil;
        }
        [self addTimestamp: (run ? @"STARTED" : @"STOPPED")];
        if (!run)
            [self logFormat: @"(Elapsed time: %.3f sec)",
             [self.endTime timeIntervalSinceDate: self.startTime]];
        [_delegate beeTest: self isRunning: _running];
        
        if (run)
            [self setUp];
        else {
            [self tearDown];
            [self closeOutput];
        }
    }
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
    
    // Save test results to local database:
    [[SavedTestRun forTest: self] save: NULL];
}


- (void)applicationDidEnterBackground: (NSNotification*)notification
{
    [self addTimestamp: @"BACKGROUND"];
}


- (void)applicationWillEnterForeground: (NSNotification*)notification
{
    [self addTimestamp: @"FOREGROUND"];
}


#pragma mark - HEARTBEAT:

- (NSTimeInterval) heartbeatInterval {
    return _heartbeat ? [_heartbeat timeInterval] : 0.0;
}

- (void) setHeartbeatInterval: (NSTimeInterval)interval {
    [_heartbeat invalidate];
    if (interval > 0 && _running) {
        _heartbeat = [NSTimer scheduledTimerWithTimeInterval: interval
                                                       target: self
                                                     selector: @selector(heartbeat)
                                                     userInfo: NULL
                                                      repeats: YES];
    } else {
        _heartbeat = nil;
    }
}


- (void) heartbeat {
}


#pragma mark - LOGGING:

- (void) openOutput {
    NSAssert(!_output, @"_output was left open");
    NSString* filename = [NSString stringWithFormat: @"%@ %@.txt",
                          [self class], [CBLJSON JSONObjectWithDate: [NSDate date]]];
    NSString* docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES)[0];
    NSString* logPath = [docsDir stringByAppendingPathComponent: filename];
    NSLog(@"**OPENING %@", logPath);
    _output = [[NSOutputStream alloc] initToFileAtPath: logPath append: NO];
    [_output open];
}

- (void) closeOutput {
    NSLog(@"** CLOSING %@", [self class]);
    [_output close];
    _output = nil;
}

- (void) writeToOutput: (NSString*)message {
    NSAssert(_output, @"Output isn't open");
    NSData* data = [message dataUsingEncoding: NSUTF8StringEncoding];
    NSInteger written = [_output write: data.bytes maxLength: data.length];
    if (written < 0)
        NSLog(@"ERROR: Can't write to log: %@", _output.streamError);
    else
        NSAssert(written == data.length, @"Only wrote %ld bytes of %lu", (long)written, (unsigned long)data.length);
    [_output write: (const uint8_t*)"\n" maxLength: 1];
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
    [self writeToOutput: message];
    return YES;
}


- (void) logMessage:(NSString *)message {
    [self addTimestamp: nil];
    [_messages addObject: message];
    if (_messages.count > kMaxMessageCount)
        [_messages removeObjectAtIndex: 0];
    [self writeToOutput: message];
    [_delegate beeTest: self loggedMessage: message];
    NSLog(@"logMessage: %@", message);
}

- (void) logFormat: (NSString*)format, ... {
    va_list args;
    va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat: format arguments: args];
    va_end(args);
    [self logMessage: message];
}

- (void) clearMessages {
    [_messages removeAllObjects];
    self.lastTimestamp = nil;
}


@end
