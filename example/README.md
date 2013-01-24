# SETUP FOR BUILDING

To build this example, PhoneGap requires that the plugin be installed in the
correct location relative to this example's www directory.  So we must copy
(or link) the plugin JavaScript code to the www directory used by the application.
We must also copy (or link) the plugin native code based on the target platform.

The details of how we do this are as follows:


# iOS

For native Objective-C code, the Xcode project directly references the code
using relative path references.

For JavaScript code, the XCode project performs the following copy operations
as part of it's pre-build process:

	cp -r $PROJECT_DIR/../www $PROJECT_DIR
	cp -r $PROJECT_DIR/../../www/phonegap $PROJECT_DIR/www


