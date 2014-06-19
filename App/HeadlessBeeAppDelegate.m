//
//  HeadlessBeeAppDelegate.m
//  Worker Bee
//
//  Created by Jens Alfke on 9/26/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "HeadlessBeeAppDelegate.h"
#import "SavedTestRun.h"
#import "BeeTest.h"


int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([HeadlessBeeAppDelegate class]));
    }
}


@implementation HeadlessBeeAppDelegate


- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"Device info: %@", [SavedTestRun deviceInfo]);

    [self performSelector: @selector(runTests) withObject: nil afterDelay: 0];

    return YES;
}


- (void) runTests {
    NSArray* allClasses = [[BeeTest allTestClasses] sortedArrayUsingComparator:^NSComparisonResult(Class c1, Class c2) {
        return [[c1 description] compare: [c2 description] options: NSNumericSearch];
    }];
    for (Class testClass in allClasses) {
        @autoreleasepool {
            NSLog(@"-------- RUNNING TEST %@", testClass);
            BeeTest* test = [[testClass alloc] init];
            test.running = YES;
            while (test.running) {
                [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                         beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
            }
        }
    }
}


@end
