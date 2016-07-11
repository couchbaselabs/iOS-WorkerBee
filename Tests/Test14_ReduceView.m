//
//  Test14_ReduceView.m
//  Worker Bee
//
//  Created by Pasin Suriyentrakorn on 7/8/16.
//  Copyright © 2016 Couchbase, Inc. All rights reserved.
//

#import "Test14_ReduceView.h"

@interface CBLView (Private)
- (void)updateIndex;
@end

@implementation Test14_ReduceView

- (void) setUp {
    [super setUp];
    [self run];
}

- (void) run {
    NSInteger numDocs = [[self configForKey: @"numDocs"] integerValue];
    
    CBLView* view = [self.database viewNamed: @"vacant"];
    [view setMapBlock: MAPBLOCK({
        id v = [doc objectForKey: @"vacant"];
        id name = [doc objectForKey: @"name"];
        if (v && name) emit(name, v);
    }) reduceBlock: REDUCEBLOCK({return @(values.count);}) version: @"1.0"];
    
    BOOL success = [self.database inTransaction: ^BOOL{
        for (int i = 0; i < numDocs; i++) {
            NSString* name = [NSString stringWithFormat:@"%@%@", @"n", @(i)];
            bool vacant = (i+2) % 2 ? 1 : 0;
            NSDictionary* props = @{@"name": name,
                                    @"apt": @(i),
                                    @"vacant": @(vacant)};
            CBLDocument* doc = [self.database createDocument];
            NSError* error;
            if (![doc putProperties: props error: &error]) {
                [self logFormat: @"ERROR: Failed to create doc %@", props];
                self.error = error;
                return NO;
            }
        }
        return YES;
    }];
    
    if (!success)
        return;
    
    [view updateIndex];
    
    uint64_t t = dispatch_benchmark(1, ^{
        CBLQuery* query = [view createQuery];
        query.mapOnly = NO;
        
        NSError* error;
        CBLQueryEnumerator* rows = [query run: &error];
        for (CBLQueryRow* row in rows) {
            if (!row.value) {
                [self logFormat: @"ERROR: Failed to enumerate the rows result"];
                break;
            }
        }
    });
    
    [self logFormat: @"%@: finished in %f ms", self, (t/1000000.0)];
}

@end
