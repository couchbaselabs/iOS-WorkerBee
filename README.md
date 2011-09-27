## Couchbase Mobile Empty App Template

This is an absolutely minimal iOS application incorporating the [Couchbase Mobile][1] framework to run [Apache CouchDB][2]. On launch it simply starts up the database server, creates a database, and then does nothing. It also contains a unit-tests target that runs one simple test against the database.

This is a starting point for your own development, not a demo (if you want to see a demo, look at [GrocerySync][7]). If you're beginning a new project, you can copy the repository, rename things and start adding code; or you can just look at this code for reference on what you need to add to an existing app to support Couchbase Mobile.

## Getting Started

These instructions assume you are familiar with how to make an iPhone app. Please follow them fully and in order the first time you build.

If you have questions or get stuck or just want to say hi, please visit the [Mobile Couchbase group][4] on Google Groups.

Prerequisite: Xcode 4.0.2 or later with the SDK for iOS 4 or later. (It's possible the project might still work with Xcode 3, but we're not testing or supporting this anymore.)

## Building The Empty App

### Download or clone the repository

You can [download a Zip archive of the current source code][8]. 

Or you can clone the repo with git:

    git clone git://github.com/couchbaselabs/iOS-EmptyApp.git

### Get the frameworks (Couchbase and CouchCocoa)

This project isn't quite standalone; it links against the Couchbase Mobile and CouchCocoa, which it expects to find in the "Frameworks" subfolder. If you've already got those, you can just copy or symlink them in. If not, here's how to get them:

1. Go to the [Couchbase Mobile for iOS home page][1] and download the release (see the Download button in the right column.) This will get you "Couchbase.framework".
2. Either [download and unzip the latest][5] compiled CouchCocoa.framework, or [check out the source code][6] and build it yourself. (Build the "iOS Framework" scheme, then find CouchCocoa.framework in the build output directory.)
3. Copy both Couchbase.framework and CouchCocoa.framework into the Frameworks directory of this project. (You don't need to drag them into Xcode; the project already has references to them.)

### Open the Xcode project

    open 'Empty App.xcodeproj'

### Build and run the empty app

1. Select the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button

Nothing much will happen; you'll see a white screen on the device/simulator. More importantly, in the log output you'll see a line like:

    Empty App[10761:b903] Couchbase is ready, go!

## To add the frameworks to your existing Xcode project

Please see the documentation on the [Couchbase Mobile][1] home page.

## License

Portions under Apache, Erlang, and other licenses.

The overall package is released under the Apache license, 2.0.

Copyright 2011, Couchbase, Inc.


[1]: http://www.couchbase.org/get/couchbase-mobile-for-ios/current
[2]: http://couchdb.apache.org
[4]: https://groups.google.com/group/mobile-couchbase
[5]: https://github.com/couchbaselabs/CouchCocoa/downloads
[6]: https://github.com/couchbaselabs/CouchCocoa/
[7]: https://github.com/couchbaselabs/iOS-Couchbase-Demo
[8]: https://github.com/couchbaselabs/iOS-EmptyApp/zipball/master