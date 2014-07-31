//
//  Test13_ITunesIndex.m
//  Worker Bee
//
//  Created by Jens Alfke on 5/9/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "Test13_ITunesIndex.h"


#undef TEST_FULL_TEXT_INDEX
#undef NEW_FTS_API // define for new full-text-search API (forestdb branch)

#define SLEEP_TIME 0


@interface CBLView (Internal)
- (int) updateIndex;
@end


@implementation Test13_ITunesIndex


#define kArtistsViewName @"x/artists"
#define kAlbumsViewName @"x/albums"
#define kTracksViewName @"y/tracks"


- (void) setUp {
    self.heartbeatInterval = 0.001;
}


- (void) heartbeat {
    @autoreleasepool {
        [self defineView];
    }
    sleep(SLEEP_TIME);

    @autoreleasepool {
        [self importLibrary];
    }
    sleep(SLEEP_TIME);

    @autoreleasepool {
        [self indexTracks];
    }
    sleep(SLEEP_TIME);

    @autoreleasepool {
        [self queryTracks];
    }
    sleep(SLEEP_TIME);

    @autoreleasepool {
        [self updateDocs];
    }
    sleep(SLEEP_TIME);

    @autoreleasepool {
        [self indexTracks];
    }

#ifdef TEST_FULL_TEXT_INDEX
    sleep(SLEEP_TIME);
    @autoreleasepool {
        [self indexFullText];
    }
#endif
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
    NSArray* tracks = [library[@"Tracks"] allValues];
    [self.database inTransaction: ^BOOL {
        for (NSDictionary* track in tracks) {
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

#if 0
                if (count % 1000 == 0)
                    [self indexTracks];
#endif
#if 0
                if (count % 100 == 0)
                    NSLog(@"... %d tracks", count);
                // Enable this to limit the size of the database:
                if (count >= 2000) {
                    NSLog(@"***** Stopping after 2000 tracks *****");
                    break;
                }
#endif
            }
        }
        return YES;
    }];
    [self logFormat: @"%.3f sec -- Adding %u documents",
                     (CFAbsoluteTimeGetCurrent() - startTime), count];


    startTime = CFAbsoluteTimeGetCurrent();
    NSString* docID = [tracks[4321] objectForKey: @"Persistent ID"];
    CBLDocument* doc = [self.database documentWithID: docID];
    __unused NSDictionary* properties = doc.properties;
    [self logFormat: @"%.6f sec -- Getting one document",
         (CFAbsoluteTimeGetCurrent() - startTime)];
}


- (void) updateDocs {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    __block unsigned count = 0;
    [self.database inTransaction:^BOOL{
        CBLQuery* allDocs = self.database.createAllDocumentsQuery;
        allDocs.prefetch = YES;
        for (CBLQueryRow* row in [allDocs run: NULL]) {
            CBLDocument* doc = row.document;
            [doc update:^BOOL(CBLUnsavedRevision *rev) {
                NSUInteger playCount = [rev[@"playCount"] unsignedIntegerValue];
                rev[@"playCount"] = @(playCount+1);
                return YES;
            } error: NULL];
            count++;
        }
        return YES;
    }];
    [self logFormat: @"%.3f sec -- Updated %u documents",
         (CFAbsoluteTimeGetCurrent() - startTime), count];
}


- (void) defineView {
    // Define a map function that emits keys of the form [artist, album, track#, trackname]
    // and values that are the track time in milliseconds;
    // and a reduce function that adds up track times.
    CBLView* view = [self.database viewNamed: kArtistsViewName];
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

    // Another view whose keys are [album, artist, track# trackname]
    CBLView* albumsView = [self.database viewNamed: kAlbumsViewName];
    [albumsView setMapBlock: MAPBLOCK({
        NSString* album = doc[@"Album"];
        if (album) {
            NSString* artist = doc[@"Artist"];
            if ([doc[@"Compilation"] boolValue])
                artist = @"-Compilations-";
            emit(@[album,
                   artist ?: [NSNull null],
                   doc[@"Track Number"] ?: [NSNull null],
                   doc[@"Name"] ?: @"",
                   @1],
                 doc[@"Total Time"]);
        }
    }) reduceBlock: REDUCEBLOCK({
        return [CBLView totalValues: values];
    })
              version: @"1"];


    // A simple view that accesses fewer properties:
    CBLView* trackNameView = [self.database viewNamed: kTracksViewName];
    [trackNameView setMapBlock: MAPBLOCK({
        NSString* name = doc[@"Name"];
        if (name)
            emit(name, nil);
    }) reduceBlock: REDUCEBLOCK({
        return [CBLView totalValues: values];
    })
              version: @"1"];
}

- (void) indexTracks {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime totalStartTime = startTime;
    [[self.database viewNamed: kArtistsViewName] updateIndex];
    [self logFormat: @"%.3f sec -- Indexing 'artists' view",
                     (CFAbsoluteTimeGetCurrent() - startTime)];
    startTime = CFAbsoluteTimeGetCurrent();
    [[self.database viewNamed: kAlbumsViewName] updateIndex];
    [self logFormat: @"%.3f sec -- Indexing 'albums' view",
                     (CFAbsoluteTimeGetCurrent() - startTime)];
    [self logFormat: @"%.3f sec -- Total indexing",
                     (CFAbsoluteTimeGetCurrent() - totalStartTime)];

    startTime = CFAbsoluteTimeGetCurrent();
    [[self.database viewNamed: kTracksViewName] updateIndex];
    [self logFormat: @"%.3f sec -- Indexing 'tracks' view",
                    (CFAbsoluteTimeGetCurrent() - startTime)];

}


- (void) queryTracks {
    static const NSUInteger kArtistCount = 1167;

    // The artists query is grouped to level 1, so it collapses all keys with the same artist.
    CBLView* view = [self.database viewNamed: kArtistsViewName];
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


#ifdef TEST_FULL_TEXT_INDEX
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
#endif


@end
