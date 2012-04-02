/* WizViewManager for PhoneGap - Handle Popup UIViews and communtications.
*
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file - wizViewManager.js
 * @about - JavaScript PhoneGap bridge for extra utilities 
 *
 *
*/



var wizViewManager = {

    create: function(viewName, options, s, f) {
        return PhoneGap.exec(s, f, "WizViewManagerPlugin", "createView", [viewName, options]);                      
    },
    
    hide:  function(viewName, animOpt, s, f) {
        return PhoneGap.exec(s, f, "WizViewManagerPlugin", "hideView", [viewName, animOpt]);                      
    },
    
    show:  function(viewName, animOpt, s, f) {
        return PhoneGap.exec(s, f, "WizViewManagerPlugin", "showView", [viewName, animOpt]);                      
    },
    
    update:  function(viewName, updateOpt, s, f) {
        return PhoneGap.exec(s, f, "WizViewManagerPlugin", "updateView", [viewName, updateOpt]);                      
    },
    
    remove:  function(viewName, s, f) {
        return PhoneGap.exec(s, f, "WizViewManagerPlugin", "removeView", [viewName]);                      
    }

    
	
};