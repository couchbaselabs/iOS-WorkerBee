//
//  BeeCouchMultipleTest.m
//  Worker Bee
//
//  Created by Li Yang on 7/17/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchMultipleTest.h"

NSString* const outputFileName = @"Bee_output.txt";
NSString* const summaryFileName = @"Bee_csv.txt";

@implementation BeeCouchMultipleTest


- (void) setUp {
    [super setUp];
    [self runMultiple];
}

+ (BOOL) isAbstractTest {
    return self == [BeeCouchMultipleTest class];
}

- (double) runOne:(int)numberOfDocuments sizeOfDocuments:(int)sizeOfDocuments {
    return 0;
}

+ (void)writeToFile:(NSString *)str toFile:(NSString *)fileName {
    
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (0 < [paths count]) {
        NSString *documentsDirPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirPath stringByAppendingPathComponent:fileName];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            // Add the text at the end of the file.
            NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
            [fileHandler seekToEndOfFile];
            [fileHandler writeData:data];
            [fileHandler closeFile];
        } else {
            // Create the file and write text to it.
            [data writeToFile:filePath atomically:YES];
        }
    }
}

- (void)logSummary:(NSString *)str {
    // Also print it to console
    [self logFormat:@"%@", str];
    [[self class] writeToFile:str toFile:outputFileName ];
    [[self class] writeToFile:str toFile:summaryFileName ];
}

- (void)logToFile:(NSString *)str {
    // Also print it to console
    [self logFormat:@"%@", str];
    [[self class] writeToFile:str toFile:outputFileName ];
}

- (void) runMultiple {
    NSDictionary* testCaseConfig = [[BeeTest config] objectForKey:NSStringFromClass([self class])];
    NSMutableArray* arrayNumberOfDocuments = [[NSMutableArray alloc] init];
    arrayNumberOfDocuments = [testCaseConfig  objectForKey:@"numbers_of_documents"];
    NSMutableArray* arraySizeofDocuments = [[NSMutableArray alloc] init];
    arraySizeofDocuments = [testCaseConfig  objectForKey:@"sizes_of_document"];
    NSMutableArray* arrayKpiNumbers = [[NSMutableArray alloc] init];
    arrayKpiNumbers = [testCaseConfig  objectForKey:@"kpi"];
    NSMutableArray* arrayBaselines = [[NSMutableArray alloc] init];
    arrayBaselines = [testCaseConfig  objectForKey:@"baseline"];
    bool kpiIsTotal = [[testCaseConfig  objectForKey:@"kpi_is_total"] boolValue];
    int repeatCount = [[testCaseConfig  objectForKey:@"repeat_count"] intValue];
    double SumKpiBaseline = [[testCaseConfig  objectForKey:@"sum_kpi_baseline"] doubleValue];

    NSString *localDate = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    [self logSummary:[NSString stringWithFormat:@"\n\n-------------------- %@ - %@", [self class], localDate]];
    [self logToFile:[NSString stringWithFormat:@"\nParams: NumberOfDocuments=%d SizeofDocument=%d repeatCount=%d", [arrayNumberOfDocuments count], [arraySizeofDocuments count], repeatCount]];

    NSMutableArray* resultNumberOfDocuments = [[NSMutableArray alloc] init];
    NSMutableArray* diffBaselinesNumberofDocuments = [[NSMutableArray alloc] init];
    int failCount = 0;
    int testCount = 0;
    double sumKpi = 0;
    
    for (int arrayNumbers = 0; arrayNumbers < [arrayNumberOfDocuments count];  arrayNumbers++) {
        int kNumberOfDocuments = [[arrayNumberOfDocuments objectAtIndex: arrayNumbers] intValue];
        NSMutableArray* arrayKpiRow = [arrayKpiNumbers objectAtIndex: arrayNumbers];
        NSMutableArray* arrayBaselineRow = [arrayBaselines objectAtIndex: arrayNumbers];
        NSMutableArray* resultSizeofDocuments = [[NSMutableArray alloc] init];
        [resultSizeofDocuments addObject:
            [NSString stringWithFormat:@"%d docs",kNumberOfDocuments]];
        NSMutableArray* diffBaselinesSizeofDocuments = [[NSMutableArray alloc] init];
        [diffBaselinesSizeofDocuments addObject:
         [NSNumber numberWithInteger:kNumberOfDocuments]];
        
        for (int arraySizes = 0; arraySizes < [arraySizeofDocuments count];  arraySizes++) {
            int kSizeofDocument = [[arraySizeofDocuments objectAtIndex: arraySizes] intValue];
            double kBaseline = [[arrayBaselineRow objectAtIndex: arraySizes] doubleValue];

            double kpiTotalTime = [[arrayKpiRow objectAtIndex: arraySizes] doubleValue];
            testCount ++;
            
            if (kpiTotalTime < 0) {
                // Skip
                [self logToFile:[NSString stringWithFormat:@"\nTest iteration #%d: SKIP. doc=%d size=%dB",testCount, kNumberOfDocuments, kSizeofDocument]];
                [resultSizeofDocuments addObject: @"-1"];
                [diffBaselinesSizeofDocuments addObject: @"SKIP"];
                continue;
            }
            
            NSMutableArray *arrayResults;
            arrayResults = [NSMutableArray array];
            
            for (int repeat = 0; repeat < repeatCount;  repeat++) {
                (void)[self database];
                // Run one iteration of the test
                double executionTime = [self runOne:kNumberOfDocuments sizeOfDocuments:kSizeofDocument];
                [arrayResults addObject: [NSNumber numberWithDouble:executionTime]];
                
                // Delete the database so a new database will be created for each iteration
                [self deleteDatabase];
            }
            double executionTimeAvg = round ( 100 * [[arrayResults valueForKeyPath:@"@avg.doubleValue"] doubleValue] ) / 100;
            double executionTimeMin = round ( 100 * [[arrayResults valueForKeyPath:@"@min.doubleValue"] doubleValue] ) / 100;
            double executionTimeMax = round ( 100 * [[arrayResults valueForKeyPath:@"@max.doubleValue"] doubleValue] ) / 100;
            double temp = round (( executionTimeAvg / kNumberOfDocuments) * 100 ) / 100;
            double executionTimeAvgPerDoc = round( temp * 100 ) / 100;

            double result;

            if (kpiIsTotal)
                result = executionTimeAvg;
            else
                result = executionTimeAvgPerDoc;

            sumKpi = sumKpi + result;
            double diffBaseline = round(((result - kBaseline )/kBaseline*100)*100)/100;
            [resultSizeofDocuments addObject:
                 [NSNumber numberWithDouble:result]];
            [diffBaselinesSizeofDocuments addObject:
             [NSNumber numberWithDouble:diffBaseline]];

            NSString* passFail;
            if(result > kpiTotalTime || diffBaseline > 10 || diffBaseline < -10) {
                passFail = @"FAIL";
                failCount++;
            } else {
                passFail = @"PASS";
            }

            [self logToFile:[NSString stringWithFormat:@"\nTest iteration #%d: %@. (docs=%d size=%dB) avg:%.02f min:%.02f max:%.02f \tkpi %.02f \tbaseline %.02f diff baseline \t%.02f%% \tList:%@", testCount, passFail, kNumberOfDocuments, kSizeofDocument,
                executionTimeAvg, executionTimeMin, executionTimeMax, kpiTotalTime, kBaseline, diffBaseline, arrayResults]];
        }
        [resultNumberOfDocuments addObject: resultSizeofDocuments];
        [diffBaselinesNumberofDocuments addObject: diffBaselinesSizeofDocuments];
    }

    // This is the number for easier comparison between test runs to see whether there are over 10% variation.  The number does not have meaning of its own because it is the sum of all test iterations
    double diffPercent = (SumKpiBaseline - sumKpi )/SumKpiBaseline*100;
    NSString* summaryPassFail = (failCount == 0) ? @"PASS" : @"FAIL";
    NSString* baselineComparePassFail = (diffPercent > 10 || diffPercent < -10) ? @"FAIL" : @"PASS";
    
    [self logSummary:[NSString stringWithFormat:@"\nSummary: %@.  %d sub-tests ran.  %d sub-tests fail (result > kpiTotalTime || diffBaseline > 10 || diffBaseline < -10) ",summaryPassFail, testCount, failCount]];
    
    [self logSummary:[NSString stringWithFormat:@"\nBaseline compare %@: sumKpi:\t%.02f \tbaseline:%.02f difference:%.02f%%", baselineComparePassFail, sumKpi, SumKpiBaseline, diffPercent]];


    NSMutableString *columHeader = [NSMutableString string];
    [columHeader appendString:[NSString stringWithFormat:@" # docs; " ]];
    for (int arrayNumbers = 0; arrayNumbers < [arraySizeofDocuments count];  arrayNumbers++) {
        [columHeader appendString:[NSString stringWithFormat:@"%@ B, ",[arraySizeofDocuments objectAtIndex: arrayNumbers]]];
    }
    [self logSummary:[NSString stringWithFormat:@"\n%@", columHeader]];

        
    for (NSMutableArray* row in resultNumberOfDocuments) {
        NSMutableString *str = [NSMutableString string];
        [str appendString:[NSString stringWithFormat:@"%@; ",[row objectAtIndex:0]]];
        for (int i = 1; i < [row count]; i++) {
            [str appendString:[NSString stringWithFormat:@"%.02f; ",[[row objectAtIndex:i] doubleValue]]];
        }
        [self logSummary:[NSString stringWithFormat:@"\n%@;", str]];
    }


    [self logSummary:[NSString stringWithFormat:@"\n--- Percentage of deviation from baselines"]];
    [self logSummary:[NSString stringWithFormat:@"\n%@", columHeader]];
    for (NSMutableArray* row in diffBaselinesNumberofDocuments) {
        NSMutableString *str = [NSMutableString string];
        for (NSNumber* num in row) {
            [str appendString:[NSString stringWithFormat:@"%.02f; ",[num doubleValue]]];
        }
        [self logSummary:[NSString stringWithFormat:@"\n%@", str]];
    }

    self.running = NO;
   
}


@end
