/* WizViewManager for cordova - Handle Popup UIViews create/remove/show/hide.
*
 * @author Ally Ogilvie  
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file - wizViewManager.js
 * @about - JavaScript cordova bridge for view management
 *
 *
*/



var wizViewManager = {

    create: function(viewName, options, s, f) {

        // stringify all vars
        for (var i in options) {
            if (options.hasOwnProperty(i)) {
                options[i] = options[i].toString();
            }
        }

        return cordova.exec(s, f, "WizViewManagerPlugin", "createView", [viewName, options]);                      
    },
    
    hide:  function(viewName, animOpt, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "hideView", [viewName, animOpt]);                      
    },
    
    show:  function(viewName, animOpt, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "showView", [viewName, animOpt]);                      
    },
    
    update:  function(viewName, updateOpt, s, f) {
        /*
        *
        * Depreciated, please use wizViewManager.load()
        */
        return cordova.exec(s, f, "WizViewManagerPlugin", "updateView", [viewName, updateOpt]);                      
                              
    },
    
    load:  function(viewName, source, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "load", [viewName, { "src" : source }]);                      
    },
    
    setLayout:  function(viewName, options, s, f) {
        
        // stringify all vars
        for (var i in options) {
            if (options.hasOwnProperty(i)) {
                options[i] = ""+options[i];
            }
        }
        
        return cordova.exec(s, f, "WizViewManagerPlugin", "setLayout", [viewName, options]);                      
    },
    
    remove:  function(viewName, s, f) {
        return cordova.exec(s, f, "WizViewManagerPlugin", "removeView", [viewName]);                       
    }
	
};
