# MWZSimpleDataUpdater

### Overview

MWZSimpleDataUpdater is a class that manages the request for and download of a single resource for an iPhone app. The class is essentially an abstraction of NSURLConnection and its delegates with a few convenience methods for updating a single resource in your app such as an SQLite or plist file. 

The class assumes a few things. 

* You have a single server-side script that handles the processing of the update. A sample AppEngine script is found in the AppEngineCode directory at the root of this project.
* The updater sends a query string to the server containing the version of the data on the device (or other pertinent information) to determine if the server should send an update. 
* If no update is available the server returns 204. If an update is available the server sends a redirect to get the data. You can pass a hash in the query string of the redirect request to verify the download if this feature is enabled on the MWZSimpleDataUpdater object. 

### Other Things To Know

* Conforming to the MWZSimpleDataUpdaterDelegate protocol gives you access to important parts of the download process and an easy way to update a download indicator.
* The class provides the ability to only check for updates if a certain amount of time has elapsed since the last update.
* The class defines custom error messages so you can respond appropriately if problems occur with the download. All download issues send the updaterWillNotDownloadData: delegate message. You can access error messages via the errorStatus property of the MWZSimpleDataUpdater object sending the message.

### Possible To Do

* Write download methods that accept blocks for users that don't need/want the hooks provided by the delegate methods.
* Make MWZSimpleDataUpdater compliant with NSCoder.
* Time dependent updates currently rely on NSUserDefaults. Store this information in the object and set an option to use or not use NSUserDefaults.
* Implement a method to allow multiple keys and values to be passed in the query string to the server-side script.

### Questions

* **How would I update multiple files?** You can just create multiple MWZSimpleDataUpdater objects or return a gzip file with all of your data in it and then process it using a 3rd party gzip library for iOS. If you create multiple MWZSimpleDataUpdater objects and you want them to all support time dependent updates you may need to do some work so they each use different keys for saving to NSUserDefaults. This won't matter as much once I get to some of the to do items above.
* **What server-side technology is this being used with?** I'm using it with Google App Engine. See the sample scripts included. 
* **Why are you writing this? Apple already provides much of this functionality with their own classes?** I'm using this as a learning experience and the code I'm writing makes sense for a few things I'm working on at the moment.