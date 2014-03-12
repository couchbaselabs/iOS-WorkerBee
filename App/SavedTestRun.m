//
//  SavedTestRun.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/10/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "SavedTestRun.h"
#import "AppDelegate.h"
#import "BeeTest.h"
#import <sys/utsname.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#include <sys/sysctl.h>


#define USE_CLOCK_SPEED 0 // Apparently you can't get the clock speed on an actual iOS device :(


@implementation SavedTestRun


CBLDatabase* sDatabase;
NSUInteger sCount;


+ (CBLDatabase*) database {
    if (!sDatabase) {
        sDatabase = [[CBLManager sharedInstance] databaseNamed: @"workerbee-tests" error: NULL];
        sCount = [sDatabase documentCount];
    }
    return sDatabase;
}

@dynamic device, serverVersion, testName, startTime, endTime, duration,
         stoppedByUser, status, error, log;

- (void) recordTest: (BeeTest*)test {
    self.device = [[self class] deviceInfo];
    self.serverVersion = CBLVersionString();
    self.testName = [[test class] testName];
    self.startTime = test.startTime;
    self.endTime = test.endTime;
    self.duration = [test.endTime timeIntervalSinceDate: test.startTime];
    if (test.stoppedByUser)
        self.stoppedByUser = YES;
    self.status = test.status;
    self.error = test.errorMessage;
    self.log = [test.messages componentsJoinedByString: @"\n"];
}

+ (SavedTestRun*) forTest: (BeeTest*)test {
    SavedTestRun* instance = [[self alloc] initWithNewDocumentInDatabase: [self database]];
    [instance recordTest: test];
    ++sCount;
    return instance;
}

+ (NSUInteger) savedTestCount {
    if (!sDatabase)
        [self database];    // trigger connection
    return sCount;
}

+ (BOOL) uploadAllTo: (NSURL*)upstreamURL error: (NSError**)outError {
    CBLReplication* repl = [[self database] replicationToURL: upstreamURL];
    [repl start];
    while (repl.running) {
        NSLog(@"Waiting for replication to finish...");
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate: [NSDate distantFuture]];
    }
    
    *outError = repl.lastError;
    NSLog(@"...Replication finished. Error = %@", repl.lastError);
    if (*outError)
        return NO;
    
    // After a successful push, delete the database because we don't need to keep the test
    // results around anymore. (Just deleting the documents would leave tombstones behind,
    // which would propagate to the server on the next push and delete them there too. Bad.)
    [sDatabase deleteDatabase: NULL];
    sDatabase = nil;
    sCount = 0;
    return YES;
}

+ (NSDictionary*) deviceInfo {
    NSProcessInfo* procInfo = [NSProcessInfo processInfo];
    UIDevice* deviceInfo = [UIDevice currentDevice];
    deviceInfo.batteryMonitoringEnabled = YES;
    return @{@"name": deviceInfo.name,
             @"model": [self deviceModelID],
             @"system": deviceInfo.systemVersion,
             @"identifier": deviceInfo.identifierForVendor.UUIDString,
             @"batteryState": [NSNumber numberWithInt: deviceInfo.batteryState],
             @"batteryLevel": @(deviceInfo.batteryLevel),
             @"uptime": @(procInfo.systemUptime),
             @"64bit_process": [NSNumber numberWithBool: sizeof(void*) > 32],
#if USE_CLOCK_SPEED
             @"CPU_freq": @([self getSysInfo: HW_CPU_FREQ]),
#endif
             @"CPU_cores": @(procInfo.activeProcessorCount),
             @"RAM": @(procInfo.physicalMemory),
             @"RAM_free": @([self freeMemory]),
             @"disk_free": [self freeDisk],
             };
}

+ (NSString*) deviceModelID {
    // Code from here; this also has a list mapping device IDs to public model names:
    // http://stackoverflow.com/questions/11197509/ios-iphone-get-device-model-and-make
    struct utsname systemInfo;
    if (uname(&systemInfo) != 0)
        return @"???";
    return @(systemInfo.machine);
}

+ (NSNumber*) freeDisk {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath: NSHomeDirectory() error: nil];
    return attrs[NSFileSystemFreeSize];
}

+ (UInt64) freeMemory {
    // http://stackoverflow.com/questions/5012886/knowing-available-ram-on-an-ios-device
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);

    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }

    /* Stats in bytes */
//    natural_t mem_used = (vm_stat.active_count +
//                          vm_stat.inactive_count +
//                          vm_stat.wire_count) * pagesize;
    UInt64 mem_free = vm_stat.free_count * pagesize;
//    natural_t mem_total = mem_used + mem_free;
//    NSLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);
    return mem_free;
}

#if USE_CLOCK_SPEED
+ (UInt64) getSysInfo: (unsigned)which {
    // https://github.com/erica/uidevice-extension/blob/master/UIDevice-Hardware.m
    unsigned results;
    size_t size = sizeof(results);
    int mib[2] = {CTL_HW, which};
    if (sysctl(mib, 2, &results, &size, NULL, 0) != 0) {
        NSLog(@"sysctl error %d", errno);
        results = 0;
    }
    return results;
}
#endif

@end
