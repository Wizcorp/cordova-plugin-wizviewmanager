/* WizViewMessenger for cordova - Handle Cross Native Window Comms
 *
 * @author Ally Ogilvie
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2013
 * @file - wizViewMessenger.js
 * @about - JavaScript for wizViewManager communications
 *
 *
 */

var WizViewMessenger = function () {};

WizViewMessenger.prototype.postMessage = function (message, targetView) { 
	// for more information on the MessageEvent API, see:
	// http://www.w3.org/TR/2008/WD-html5-20080610/comms.HTMLElement
	
	// wizPostMessage://origin?target?data
	
	// Check message type
    var type;
    if (Object.prototype.toString.call(message) === "[object Array]") {
        type = "Array";
        message = JSON.stringify(message);
    } else if (Object.prototype.toString.call(message) === "[object String]") {
        type = "String";
    } else if (Object.prototype.toString.call(message) === "[object Number]") {
        type = "Number";
        message = JSON.stringify(message);
    } else if (Object.prototype.toString.call(message) === "[object Boolean]") {
        type = "Boolean";
        message = message.toString();
    } else if (Object.prototype.toString.call(message) === "[object Function]") {
        type = "Function";
        message = message.toString();
    } else if (Object.prototype.toString.call(message) === "[object Object]") {
        type = "Object";
        message = JSON.stringify(message);
    } else {
    	console.error("WizViewMessenger posted unknown type!");
        return;
    }
    
	var iframe = document.createElement('IFRAME');
	iframe.setAttribute('src', 'wizPostMessage://'+ window.encodeURIComponent(window.name) + '?' + window.encodeURIComponent(targetView) + '?' + window.encodeURIComponent(message) + '?' + type );
	document.documentElement.appendChild(iframe);
	iframe.parentNode.removeChild(iframe);
	iframe = null;		
};
    
WizViewMessenger.prototype.__triggerMessageEvent = function (origin, target, data, type) { 
    // Trigger message event
    origin = decodeURIComponent(origin);
    target = decodeURIComponent(target);
    data = decodeURIComponent(data);

    // Check message type
    if (type === "Array") {
        data = JSON.parse(data);
    } else if (type === "String") {
        // Stringy String String
    } else if (type === "Number") {
        data = JSON.parse(data);
    } else if (type === "Boolean") {
        data = Boolean(data);
    } else if (type === "Function") {
        // W3C says nothing about functions, will be returned as string.
    } else if (type === "Object") {
        data = JSON.parse(data);
    } else {
    	console.error("Message Event received unknown type!");
        return;
    }
	
	var event = document.createEvent("HTMLEvents");
	event.initEvent("message", true, true);
	event.eventName = "message";
	event.memo = { };
	event.origin = origin;
	event.source = target;
	event.data = data;
	dispatchEvent(event);
};

module.exports = new WizViewMessenger();
