//
//  Test13_ITunesIndex.m
//  Worker Bee
//
//  Created by Jens Alfke on 5/9/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test13_ITunesIndex.h"


@interface CBLView (Internal)
- (int) updateIndex;
@end


@implementation Test13_ITunesIndex


- (void) setUp {
    self.heartbeatInterval = 0.001;
}


- (void) heartbeat {
    @autoreleasepool {
        [self importLibrary];
    }
    sleep(1);
    @autoreleasepool {
        [self indexTracks];
    }
    sleep(1);
    @autoreleasepool {
        [self queryTracks];
    }
    sleep(1);
    @autoreleasepool {
        [self indexFullText];
    }
    self.running = NO;
}


- (void) importLibrary {
    NSURL* libraryURL = [[NSBundle mainBundle] URLForResource: @"iTunes Music Library"
                                                withExtension: @"xml"];
    NSDictionary* library = [NSDictionary dictionaryWithContentsOfURL: libraryURL];
    NSAssert(library, @"Couldn't read %@", libraryURL.path);

    NSArray* keysToCopy = keysToCopy = @[@"Name", @"Artist", @"Album", @"Genre", @"Year",
                                         @"Total Time", @"Track Number", @"Compilation"];

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    __block unsigned count = 0;
    [self.database inTransaction: ^BOOL {
        for (NSDictionary* track in [library[@"Tracks"] allValues]) {
            NSString* trackType = track[@"Track Type"];
            if (![trackType isEqual: @"File"] && ![trackType isEqual: @"Remote"])
                continue;
            @autoreleasepool {
                NSString* documentID = track[@"Persistent ID"];
                if (!documentID)
                    continue;
                NSMutableDictionary* props = [NSMutableDictionary dictionary];
                for(NSString* key in keysToCopy) {
                    id value = track[key];
                    if (value)
                        props[key] = value;
                }
                ++count;
                /*NSLog(@"#%4u: %@ \"%@\"",
                 count, [props objectForKey: @"Artist"], [props objectForKey: @"Name"]);*/
                NSError* error;
                if (![[self.database documentWithID: documentID] putProperties: props
                                                                         error: &error])
                    NSAssert(NO, @"Couldn't save doc: %@", error);
            }
        }
        return YES;
    }];
    [self logFormat: @"%.3f sec -- Adding %u documents",
                     (CFAbsoluteTimeGetCurrent() - startTime), count];
}


- (void) indexTracks {
    // Define a map function that emits keys of the form [artist, album, track#, trackname]
    // and values that are the track time in milliseconds;
    // and a reduce function that adds up track times.
    CBLView* view = [self.database viewNamed: @"tracks"];
    [view setMapBlock: MAPBLOCK({
        NSString* artist = doc[@"Artist"];
        NSString* name = doc[@"Name"];
        if (artist && name) {
            if ([doc[@"Compilation"] boolValue]) {
                artist = @"-Compilations-";
            }
            emit(@[artist,
                   doc[@"Album"] ?: [NSNull null],
                   doc[@"Track Number"] ?: [NSNull null],
                   name,
                   @1],
                 doc[@"Total Time"]);
        }
    }) reduceBlock: REDUCEBLOCK({
        return [CBLView totalValues: values];
    })
              version: @"3"];

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    [view updateIndex];
    [self logFormat: @"%.3f sec -- Indexing 'tracks' view",
                     (CFAbsoluteTimeGetCurrent() - startTime)];
}


- (void) queryTracks {
    static const NSUInteger kArtistCount = 1167;

    // The artists query is grouped to level 1, so it collapses all keys with the same artist.
    CBLView* view = [self.database viewNamed: @"tracks"];
    CBLQuery* q = [view createQuery];
    q.groupLevel = 1;
    NSMutableArray* artists = [NSMutableArray arrayWithCapacity: kArtistCount];

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    for (CBLQueryRow* row in [q run: NULL]) {
        NSString* artist = row.key0;
        [artists addObject: artist];
    }
    [self logFormat: @"%.3f sec -- Grouped query (%lu rows)",
                     (CFAbsoluteTimeGetCurrent() - startTime), (unsigned long)artists.count];
//    NSAssert(artists.count == kArtistCount, @"Wrong artist count %ld; should be %ld",
//             (unsigned long)artists.count, (unsigned long)kArtistCount);
}

//#define NEW_FTS_API

- (void) indexFullText {
    // Another view that creates a full-text index of everything:
    CBLView* fullTextView = [self.database viewNamed: @"fullText"];
#ifdef NEW_FTS_API
    fullTextView.indexType = kCBLFullTextIndex;
#endif
    [fullTextView setMapBlock: MAPBLOCK({
#ifdef NEW_FTS_API
        emit(doc[@"Artist"], nil);
        emit(doc[@"Album"], nil);
        emit(doc[@"Name"], nil);
#else
        if (doc[@"Artist"]) emit(CBLTextKey(doc[@"Artist"]), nil);
        if (doc[@"Album"])  emit(CBLTextKey(doc[@"Album"]), nil);
        if (doc[@"Name"])   emit(CBLTextKey(doc[@"Name"]), nil);
#endif
    })
                      version: @"1"];

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    [fullTextView updateIndex];
    [self logFormat: @"%.3f sec -- Indexing full-text view",
                     (CFAbsoluteTimeGetCurrent() - startTime)];
}


@end
