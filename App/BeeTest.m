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
}
@property (retain) NSString* lastTimestamp;
@end


@implementation BeeTest

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
                    && c != self) {
                NSLog(@"BeeTets: Found test class %@", classes[i]);
                [testClasses addObject: classes[i]];
            }
        }
        free(classes);
        
        sAllTestClasses = [testClasses copy];
    }
    return sAllTestClasses;
}

+ (NSString*) displayName {
    return NSStringFromClass(self);
}


@synthesize delegate=_delegate, error = _error, messages = _messages, lastTimestamp = _lastTimestamp;

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
    [_error release];
    [super dealloc];
}

- (BOOL) running {
    return _running;
}

- (void) setRunning:(BOOL)run {
    if (run != _running) {
        _running = run;
        if (run)
            [self clearMessages];
        [self addTimestamp: (run ? @"STARTED" : @"STOPPED")];
        [_delegate beeTest: self isRunning: _running];
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

@end
