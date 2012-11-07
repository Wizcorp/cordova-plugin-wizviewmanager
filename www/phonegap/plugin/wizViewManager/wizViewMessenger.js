/* WizViewMessenger for cordova - Handle Popup UIViews communtications.
 *
 * @author Chris Wynn
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file - wizViewMessenger.js
 * @about - JavaScript for wizViewManager communications
 *
 *
 */

var wizViewMessenger = {

	message: function(targetView, msg) { 
		var iframe = document.createElement('IFRAME');
		iframe.setAttribute('src', 'wizMessageView://'+ window.encodeURIComponent(targetView)+ '?'+ window.encodeURIComponent(msg) );
		document.documentElement.appendChild(iframe);
		iframe.parentNode.removeChild(iframe);
		iframe = null;
    }
	
};
