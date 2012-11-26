# PLUGIN: 

phonegap-plugin-wizViewManager<br />
version : 1.9 (Canvas beta)<br />
last update : 26/11/2012<br />


# CHANGELOG: 
<br />
- New canvas view!


# KNOWN ISSUES:
<br />
- For canvas; show() and hide() do not support animations.
- Probably super buggy!


# DESCRIPTION :

PhoneGap plugin for;

creating,<br />
removing,<br />
showing,<br />
hiding,<br />
messaging (cross communication of strings to each and every view),<br />
animating,<br />
resizing,<br />
loading source into views.





# INSTALL (iOS): #

Project tree<br />

<pre><code>
project
	/ www
		/ phonegap
			/ plugin
				/ wizViewManager
					/ wizViewManager.js	
					/ wizViewMessenger.js
					/ wizViewCanvasManager.js
					/ ejecta.js

	/ ios
		/ project
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
</code></pre>



1 ) Arrange files to structure seen above.

2 ) Add to Cordova.plist in the plugins array;<br />
Key : wizViewManager<br />
Type : String<br />
Value : wizViewManager<br />

3 ) Add \<script\> tag to your index.html<br />
\<script type="text/javascript" charset="utf-8" src="phonegap/plugin/wizViewManager/wizViewManager.js"\>\</script\><br />
\<script type="text/javascript" charset="utf-8" src="phonegap/plugin/wizViewManager/wizViewMessenger.js"\>\</script\><br />
(assuming your index.html is setup like tree above)


4 ) Add the following to header AND library search paths in Xcode Build Settings<br />
"$(SRCROOT)/modules/phonegap-plugin-wizViewManager/ios/project/Plugins/WizViewManagerPlugin"

5 ) Follow example code below.






<br />
<br />
<br />
# EXAMPLE CODE : #

<br />
<br />
Creating a view<br />
<pre><code>
wizViewManager.create(String viewName, JSONObject options, Function success, Function fail);

    * Height overrides top and bottom. Width overrides left and right.
    * Top, bottom,left,right,width,height all take floats (0.25) or string "25%" as percents, int (25) as pixcels.
    * Example options object; 

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
</code></pre>


Load source into view<br />
<pre><code>
wizViewManager.load(String viewName, String URI or URL, Function success, Function fail);
</code></pre>


Change or set the Layout of a view<br />
<pre><code>
wizViewManager.setLayout(String viewName, JSONObject options, Function success, Function fail);
    * Height overrides top and bottom. Width overrides left and right.  
    * Top, bottom,left,right,width,height all take floats (0.25) or string "25%" as percents, int (25) as pixcels.
    * Example options object; 

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
</code></pre>



Remove a view<br />
```
wizViewManager.remove(String viewName, Function success, Function fail); 
```


Show a view<br />
<pre><code>
wizViewManager.show(String viewName, JSONObject animOptions, Function success, Function fail);

    * Animation Types; 

slideInFromLeft - iOS
slideInFromRight - iOS
slideInFromTop - iOS
slideInFromBottom - iOS
fadeIn - iOS/Android
zoomIn - iOS/Android

    * Example animOptions object; 

animation : {

    "type": "fadeIn", [string - default : fadeIn] 
    "duration": "300", [int - default : 500] 

}; 
</code></pre>



Hide a view<br />
<pre><code>
wizViewManager.hide(String viewName, JSONObject animOptions, Function success, Function fail);

    * Animation Types; 

slideOutFromLeft - iOS
slideOutFromRight - iOS
slideOutFromTop - iOS
slideOutFromBottom - iOS
fadeOut - iOS/Android
zoomOut - iOS/Android

    * Example animOptions object; 

animation : {

    "type": "fadeOut", [string - default : fadeOut] 
    "duration": "300", [int - default : 500] 

}; 
</code></pre>

Message a view<br />
To send a messsage to a view, add this to the html you wish to send from use...
<pre><code>
wizViewMessenger.message(targetView, message);
	* targetView is the string name of the target view.
	* message is the message string
    * To send a JSON object as the message, stringify it before sending using:  message = JSON.stringify(myObject)
</code></pre>

add a receiver to your html that gets the message...
<pre><code>
function wizMessageReceiver(message) 
{
    // your data comes in here
    console.log('i got :' + message);
                        
}
	* message is the message string
    * To receive a JSON object as the message, parse the object after receiving using:  myObject = JSON.parse(message)
</code></pre>

