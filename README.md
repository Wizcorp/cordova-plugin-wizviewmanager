# phonegap-plugin-wizViewManager: 

PhoneGap Version : 2.7<br />
last update : 13/06/2013<br />


# Known Issues

- Canvas view is iOS only (possible move to separate Ejecta plugin?)
- For canvas; show() and hide() do not support animations.
- Webviews on Android do not currently support animations.


# Description

WizViewManager allows a developer to spawn multiple webviews from JavaScript. This is similar to the newer API in Cordova's ChildBrowser. WizViewManager however has a broader and simpler API.
WizViewManager APIs allows for
- creating
- removing
- showing
- hiding
- messaging (cross communication of strings to each and every view),<br />
- animating
- resizing
- loading local/non-local pages into views.

WizViewManager also has **Ejecta** integration for iOS. Use this to create "canvas views". Canvas views can also use the messaging API to access other PhoneGap APIs on Cordova's main view.


# Install (iOS)

Project tree<br />

	project
		/ www
			/ phonegap
				/ plugin
					/ wizViewManager
						/ wizViewManager.js	
						/ wizViewMessenger.js
						/ wizViewCanvasManager.js
						/ ejecta.js

		/ Plugins
			/ wizViewManager
				/ wizViewManager.h
				/ wizViewManager.m
				/ wizCanvasView.h
				/ wizCanvasView.m
				/ wizWebView.h
				/ wizWebView.m
				/ JavaScriptCore /
				/ lodepng /

1) Arrange files to structure seen above.

2) Add to config.xml in the plugins array;

```<plugin name="WizViewManagerPlugin" value="WizViewManagerPlugin" />```

3) Add `<script>` tag to your index.html

```<script type="text/javascript" charset="utf-8" src="phonegap/plugin/wizViewManager/wizViewManager.js"></script>```

```<script type="text/javascript" charset="utf-8" src="phonegap/plugin/wizViewManager/wizViewMessenger.js"></script>```

(assuming your index.html is setup like tree above)

4) Add the following to header AND library search paths in Xcode Build Settings

```$(SRCROOT)/modules/phonegap-plugin-wizViewManager/ios/project/Plugins/WizViewManagerPlugin```

5) Follow example code below.

# Install (Android)

Project tree<br />

	project
		/ assets
			/ www
				/ phonegap
					/ plugin
						/ wizViewManager
							/ wizViewManager.js	
							/ wizViewMessenger.js
						
		/ src
			/ jp 
				/ wizcorp 
					/ phonegap 
						/ plugins
							/ wizViewManager
								/ WizViewManagerPlugin.java
								/ WizWebView.java

1) Arrange files to structure seen above.

2) Add to config.xml in the plugins array;

```<plugin name="WizViewManagerPlugin" value="jp.wizcorp.phonegap.plugin.wizViewManager.WizViewManagerPlugin" />```

```<url-filter name="WizViewManagerPlugin" value="wizmessageview://"/>```

3) Add `<script>` tag to your index.html

```<script type="text/javascript" charset="utf-8" src="phonegap/plugin/wizViewManager/wizViewManager.js"></script>```

```<script type="text/javascript" charset="utf-8" src="phonegap/plugin/wizViewManager/wizViewMessenger.js"></script>```

(assuming your index.html is setup like tree above)

4) Follow example code below.

# Example Code

**Creating a view**

	wizViewManager.create(String viewName, JSONObject options, Function success, Function fail);

- Height overrides top and bottom. Width overrides left and right.
- Top, bottom,left,right,width,height all take floats (0.25) or string "25%" as percents, int (25) as pixcels.
- Example options object; 

		{
    		"src": "http://google.com" [URL/URI to load]
    		"type": "canvas" [view component to create - webview / canvas / default is webview]
    		"height": "300", [pixels - default : fills height] 
    		"width": "300", [pixels - default : fills width] 
    		"x": "0", [pixels - default : 0] 
    		"y": "0", [pixels - default : 0] 
    		"top": "0", [pixels or percent - default : 0]
    		"bottom": "0", [pixels or percent - default : 0]
    		"left": "0", [pixels or percent - default : 0]
    		"right": "0", [pixels or percent - default : 0]
		}; 


**Load source into view**

	wizViewManager.load(String viewName, String URI or URL, Function success, Function fail);

**Change or set the Layout of a view**

	wizViewManager.setLayout(String viewName, JSONObject options, Function success, Function fail);
	
- Height overrides top and bottom. Width overrides left and right.  
- Top, bottom,left,right,width,height all take floats (0.25) or string "25%" as percents, int (25) as pixcels.
- Example options object; 

		{
			"height": "300", [pixels - default : fills height] 
			"width": "300", [pixels - default : fills width] 
			"x": "0", [pixels - default : 0] 
			"y": "0", [pixels - default : 0] 
			"top": "0", [pixels or percent - default : 0]
			"bottom": "0", [pixels or percent - default : 0] 
			"left": "0", [pixels or percent - default : 0] 
			"right": "0", [pixels or percent - default : 0] 
		}; 

**Remove a view**

	wizViewManager.remove(String viewName, Function success, Function fail); 

**Show a view**
	
	wizViewManager.show(String viewName, JSONObject animOptions, Function success, Function fail);

Animation Types; 

- slideInFromLeft - iOS
- slideInFromRight - iOS
- slideInFromTop - iOS
- slideInFromBottom - iOS
- fadeIn - iOS/Android
- zoomIn - iOS/Android```

Example animOptions object; 

	animation : {
    	"type": "fadeIn", [string - default : fadeIn] 
    	"duration": "300", [int - default : 500] 
	}; 

**Hide a view**
	
	wizViewManager.hide(String viewName, JSONObject animOptions, Function success, Function fail);

Animation Types; 

- slideOutFromLeft - iOS
- slideOutFromRight - iOS
- slideOutFromTop - iOS
- slideOutFromBottom - iOS
- fadeOut - iOS/Android
- zoomOut - iOS/Android

Example animOptions object; 

	animation : {
	    "type": "fadeOut", [string - default : fadeOut] 
    	"duration": "300", [int - default : 500] 
	}; 

**Messaging views**

To send a messsage to a view based on W3C post message API...
for more information on the MessageEvent API, see:
[http://www.w3.org/TR/2008/WD-html5-20080610/comms.HTMLElement](http://www.w3.org/TR/2008/WD-html5-20080610/comms.HTMLElement)

	wizViewMessenger.postMessage(Data message, String targetView);
	
	message is Data as Array, String, Number, Object
	targetView is the string name of the target view.
	to reach Cordova window, targetView = "mainView"

add an event listener in the html that wishes to receive the message...
	
	window.addEventListener( 'message', wizMessageReceiver );

Example receiver;
	
	function wizMessageReceiver (event) {
    	// event data object comes in here    
	}

