/* WizViewManager for cordova - Handle Popup UIViews and communtications.
*
 * @author Ally Ogilvie
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file - wizViewManager.js
 * @about - JavaScript cordova bridge for extra utilities 
 *
 *
*/





var wizViewManager = {

    create: function(viewName, options, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "createView", [viewName, options]);                      
    },
    
    hide:  function(viewName, animOpt, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "hideView", [viewName, animOpt]);                      
    },
    
    show:  function(viewName, animOpt, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "showView", [viewName, animOpt]);                      
    },
    
    update:  function(viewName, updateOpt, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "updateView", [viewName, updateOpt]);                      
    },
    
    remove:  function(viewName, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "removeView", [viewName]);                      
    }

    
	
};