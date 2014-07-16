//
//  PerfTestScenario2.m
//  Worker Bee
//
//  Created by Ashvinder Singh on 2/7/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//
#import <malloc/malloc.h>
#import "Test3_CreateDocsWithAttachments.h"
#import <CouchbaseLite/CouchbaseLite.h>

@implementation Test3_CreateDocsWithAttachments

- (void) heartbeat {
    [self logFormat: @"Starting Test"];
    @autoreleasepool {
        NSDictionary* testCaseConfig = [[BeeTest config] objectForKey:NSStringFromClass([self class])];
        NSMutableArray* arrayNumberOfDocuments = [[NSMutableArray alloc] init];
        arrayNumberOfDocuments = [testCaseConfig  objectForKey:@"numbers_of_documents"];
        NSMutableArray* arraySizeofDocument = [[NSMutableArray alloc] init];
        arraySizeofDocument = [testCaseConfig  objectForKey:@"sizes_of_document"];
        NSMutableArray* arrayKpis = [[NSMutableArray alloc] init];
        arrayKpis = [testCaseConfig  objectForKey:@"kpi_total_time"];
        int repeatCount = [[testCaseConfig  objectForKey:@"repeat_count"] intValue];
        [self logFormat:@"Running with params: %d NumberOfDocuments, %d SizeofDocument, repeatCount=%d", [arrayNumberOfDocuments count], [arraySizeofDocument count], repeatCount];
        int failCount = 0;
        int testCount = 0;

        for (int arrayNumbers = 0; arrayNumbers < [arrayNumberOfDocuments count];  arrayNumbers++) {
            int kNumberOfDocuments = [[arrayNumberOfDocuments objectAtIndex: arrayNumbers] intValue];
            NSMutableArray* arrayKpiNumbers = [arrayKpis objectAtIndex: arrayNumbers];

            for (int arraySizes = 0; arraySizes < [arraySizeofDocument count];  arraySizes++) {
                int kSizeOfAttachment = [[arraySizeofDocument objectAtIndex: arraySizes] intValue];
                double kpiTotalTime = [[arrayKpiNumbers objectAtIndex: arraySizes] doubleValue];

                if (kpiTotalTime == -1) {
                    // Skip
                    [self logFormat:@"Result %d: SKIP for creating \t%d documents, \tsize %dB",testCount, kNumberOfDocuments, kSizeOfAttachment];
                    continue;
                }

                NSMutableArray *arrayResults;
                arrayResults = [NSMutableArray array];

                for (int repeat = 0; repeat < repeatCount;  repeat++) {
                    @autoreleasepool {
                        NSMutableString *str = [NSMutableString stringWithCapacity:kSizeOfAttachment];
                        for (int i = 0; i< kSizeOfAttachment; i++) {
                            [str appendString:@"1"];
                        }
                        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];

                        NSDate *start = [NSDate date];
                        [self.database inTransaction:^BOOL{
                            for (int j = 0; j < kNumberOfDocuments; j++) {
                                NSString *key = [NSString stringWithFormat:@"%d",repeat];
                                @autoreleasepool {
                                    CBLDocument* doc = [self.database createDocument];
                                    CBLUnsavedRevision* rev = doc.newRevision;
                                    [rev setAttachmentNamed:key withContentType:@"image/jpg" content:data];

                                    NSError* error;
                                    CBLSavedRevision* saved = [rev save:&error];

                                    if (!saved){
                                        [self logFormat: @"!!! Failed to attach %@", data];
                                        self.error = error;
                                    }
                                }
                            }
                            return YES;
                        }];

                        NSDate *methodFinish = [NSDate date];
                        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
                        NSNumber *executionTimeNSNumber = [NSNumber numberWithDouble:executionTime];
                        [arrayResults addObject: executionTimeNSNumber];

                        // Delete the database so a new database will be created for each iteration
                        [self deleteDatabase];
                    }
                }
                testCount ++;
                double executionTimeAvg = [[arrayResults valueForKeyPath:@"@avg.doubleValue"] doubleValue];
                double executionTimeMin = [[arrayResults valueForKeyPath:@"@min.doubleValue"] doubleValue];
                double executionTimeMax = [[arrayResults valueForKeyPath:@"@max.doubleValue"] doubleValue];
                NSString* passFail = (executionTimeAvg <= kpiTotalTime) ? @"PASS" : @"FAIL";
                if ([passFail isEqualToString:@"FAIL"])  {
                    failCount++;
                }
                [self logFormat:@"Result %d: %@. Time to create \t%d documents, \tsize %dB, \t\tkpi %.2fms: \tavg:%.2f \tmin:%.2f \tmax:%.2f.  \tAvg_Per_Doc:%.2f \tList:%@",testCount, passFail, kNumberOfDocuments, kSizeOfAttachment, kpiTotalTime, executionTimeAvg, executionTimeMin, executionTimeMax, executionTimeAvg/kNumberOfDocuments, arrayResults];
            }
        }

        if (failCount == 0)
            [self logFormat:@"Summary: PASS.  %d test iteration completed successfully", testCount];
        else
            [self logFormat:@"Summary: FAIL.  Among %d test iterations,  %d tests failed.",testCount, failCount];
        self.running = NO;

    }
}


- (void) setUp {
    [super setUp];
    self.heartbeatInterval = 1.0;
}


@end
