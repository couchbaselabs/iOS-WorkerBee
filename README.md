## Couchbase Lite Workflow Test App

This iOS app is a shell for long-running workflow tests of the [Couchbase Lite][1] framework.

## Getting Started

These instructions assume you are familiar with how to make an iOS app. Please follow them fully and in order the first time you build.

If you have questions or get stuck or just want to say hi, please visit the [Mobile Couchbase group][4] on Google Groups.

Prerequisite: Xcode 4.3 or later with the SDK for iOS 6 or later.

## Building The App

### Download or clone the repository

Clone the repo with git:

    git clone git://github.com/couchbaselabs/WorkerBee.git

### Get the framework

This project isn't quite standalone; it links against the [Couchbase Lite][1] framework, which it expects to find in the `Frameworks` subfolder. Build that framework, or download a precompiled build, and copy or symlink the iOS version of `CouchbaseLite.framework` into `Frameworks`.

### Open the Xcode project

    open 'Worker Bee.xcodeproj'

### Build and run the app

1. Select the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button.

Once in the app, you'll see a list of available tests. Tap the on/off switch next to a test to start or stop it. (Some tests stop automatically, some run forever till you stop them.)

To see more info about a test, tap its name to navigate to its page. This will show the test's log output. You can also start and stop the test from this page. The test will keep running whether you're on its page or not.

Test output is saved to the app's Documents directory. If you're running on a real device, you can access this directory by tethering the device, selecting it in iTunes, going to the Apps tab, scrolling down to the File Sharing list, then selecting "Worker Bee" in the list. In the simulator, you can look in the Xcode console output for lines starting with `** OPENING` to see the paths to the log files.

## Adding Your Own Tests

Just create a new subclass of BeeCouchTest. Read API docs for that class and its parent BeeTest to see what you can do, and look at the existing tests for inspiration. 

Generally you'll override -setUp, set a heartbeatInterval, and override -heartbeat to perform periodic activity. The framework takes care of creating a fresh database for you to work with.

## Uploading Test Results

Test results are saved into a local Couchbase Lite database and can be replicated to a remote database server. This is very useful for collecting and analyzing data from multiple devices.

To enable replication, open TestListController.m, uncomment the definition of `kUpstreamSavedTestDatabaseURL`, and set its value to the URL of the database to upload to. This can be the Couchbase Sync Gateway, or any CouchDB-compatible database. (It does need to allow anonymous push replication, unless you want to extend SavedTestRun.m to support authentication.)

## License

Released under the Apache license, 2.0.

Background pattern images are from [subtlepatterns.com][9], released under a Creative Commons Attribution 3.0 Unported License.  
Bee icon is 19th-century clip art, public domain.

Copyright 2011-2013, Couchbase, Inc.


[1]: https://github.com/couchbase/Couchbase-Lite-iOS
[4]: https://groups.google.com/group/mobile-couchbase
[9]: http://subtlepatterns.com/
