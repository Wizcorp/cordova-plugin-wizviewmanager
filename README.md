# phonegap-plugin-wizViewManager 

- PhoneGap Version : 3.0
- last update : 15/10/2013

# Description

PhoneGap plugin for

- creating
- removing
- showing
- hiding
- messaging (cross communication of strings to each and every view)
- animating
- resizing
- loading source into views.

## Install (with Plugman - example iOS) 

	cordova plugin add https://github.com/Wizcorp/phonegap-plugin-wizSpinner/tree/v3.0
	cordova build ios
	
	< or >
	
	phonegap local plugin add https://github.com/Wizcorp/phonegap-plugin-wizSpinner
	phonegap build ios

## APIs

### Create

There is no limit to the amount of views you can create, but you cannot re-use the same name.

	wizViewManager.create(String viewName, JSONObject options, Function success, Function fail);

Options list;

	{
	    src: "http://google.com" [local or remote http]
	    height: 300, [accepts "300px", "30%" - default : fills height] 
	    width: 300, [accepts "300px", "30%" - default : fills width] 
	    x: 0,
	    y: 0, 
	    top: 0, [string, pixels or percent - default : 0]
	    bottom: 0, [string, pixels or percent - default : 0]
	    left: 0, [pixels or percent - default : 0]    
	    right:0, [string, pixels or percent - default : 0]
	}; 
	
**NOTE:- Android only accepts ints**

### Load

	wizViewManager.load(String viewName, String URI or URL, Function success, Function fail);
	
	
### Set Layout
	
	wizViewManager.setLayout(String viewName, JSONObject options, Function success, Function fail);

See `create` API for a list of options.

### Show

	wizViewManager.show(String viewName, JSONObject options, Function success, Function fail);

**NOTE:- Animations not currently supported on Android, they are ignored**

A list of animations;

- slideInFromLeft
- slideInFromRight
- slideInFromTop
- slideInFromBottom
- fadeIn

Example options Object;

	options : {
		animation: {
		   	type: "fadeIn", 
	    	duration: "300"
	    }
	};

### Hide

	wizViewManager.hide(String viewName, JSONObject options, Function success, Function fail);

**NOTE:- Animations not currently supported on Android, they are ignored**

A list of animations;

- slideOutToLeft
- slideOutToRight
- slideOutToTop
- slideOutToBottom
- fadeOut

Example options Object;

	options : {
		animation : {
    		type: "fadeOut",
    		duration: "300"
    	}
	}; 
	
### Messaging

To send a messsage to a view based on W3C post message API... for more information on the MessageEvent API, see: [http://www.w3.org/TR/2008/WD-html5-20080610/comms.HTMLElement](http://www.w3.org/TR/2008/WD-html5-20080610/comms.HTMLElement)

	wizViewMessenger.postMessage(Data message, String targetView);

- `message` is Data as Array, String, Number, Object
- `targetView` is the string name of the target view.
- to reach Cordova window, `targetView` = `"mainView"`

Add an event listener in the html that wishes to receive the message...

	window.addEventListener('message', wizMessageReceiver);

Example receiver;

	function wizMessageReceiver (event) {
	    // Event data object comes in here    
	}
