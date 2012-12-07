/* WizViewManager for cordova - Handle Views create/remove/show/hide etc.
*
 * @author Ally Ogilvie  
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2012
 * @file - wizViewManager.js
 * @about - JavaScript cordova bridge for view management
 *
 *
*/

/* usage:
	function failure(error) {
		console.error(error);
	}

	wizViewManager.create(
		'popup',
		{ type: 'webview', width: '100%', height: '100%' },
		function success(popupView) {
			popupView.load(
				'popup.html',
				function success() {
					console.log('popup loaded!');
				},
				failure);
		},
		failure);
*/

(function (window) {

	// inheritor helper for each library (copy please)
	function inherits(ctor, superCtor) {
		ctor.prototype = Object.create(superCtor.prototype, {
			constructor: { value: ctor, enumerable: false, writable: true, configurable: true }
		});
	};

	// object stringifier helper
	function propsToString(obj) {
		// stringify all vars
		for (var i in obj) {
            if (obj.hasOwnProperty(i)) {
                obj[i] = '' + obj[i];
            }
        }
    }

	// View for Cordova
	function View(name) {
		this.name = name;
	}


	View.prototype.postMessage = function (message) {
        cordova.exec(null, null, "WizViewManagerPlugin", "postMessage", [message, this.name]);
	};


	View.create = function (name, options, success, failure) {
		propsToString(options);
        cordova.exec(success, failure, "WizViewManagerPlugin", "createView", [name, options]);
	};


	View.prototype.remove = function (success, failure) {
        cordova.exec(success, failure, "WizViewManagerPlugin", "removeView", [this.name]);
	};


	View.prototype.show = function (animOptions, success, failure) {
        cordova.exec(success, failure, "WizViewManagerPlugin", "showView", [this.name, animOptions]);                      
	};


	View.prototype.hide = function (animOptions, success, failure) {
        cordova.exec(success, failure, "WizViewManagerPlugin", "hideView", [this.name, animOptions]);                      
	};


    View.prototype.load = function (source, success, failure) {
        cordova.exec(success, failure, "WizViewManagerPlugin", "load", [this.name, { src: source }]);
	};


    View.prototype.setLayout = function (options, success, failure) {
		propsToString(options);
        cordova.exec(success, failure, "WizViewManagerPlugin", "setLayout", [this.name, options]);
    };



	// WizViewManager parent class for each library (copy please)
	function WizViewManager(name) {
		this.name = name;
		this.views = {};
	}


	WizViewManager.prototype.receivedMessage = function (message, senderName) {
		// for more information on the MessageEvent API, see:
		// http://www.w3.org/TR/2008/WD-html5-20080610/comms.html

		var sender = this.views[senderName];

		var event = document.createEvent('MessageEvent');
		event.initMessageEvent('typeArg???', true, true, message, senderName, '', sender);
		window.dispatchEvent(event);
	};


	WizViewManager.prototype.throwError = function (cb, error) {
		if (cb) {
			cb(error);
		} else {
			throw error;
		}
	};


	WizViewManager.prototype.create = function (name, options, success, failure) {
		if (!View.create) {
			return this.throwError(failure, new Error('The create API is not implemented, while trying to create: ' + name));
		}

		var views = this.views;
		// wrap around the success callback, so we can return a View instance

		function successWrapper() {
			var view = new View(name);

			views[name] = view;

			success(view);
		}

		View.create(name, options, successWrapper, failure);
	};


	WizViewManager.prototype.show = function (name, animOptions, success, failure) {
		if (!this.views[name]) {
			return this.throwError(failure, new Error('Show Error with view name: ' + name + '. View does not exist'));
		}
	
		this.views[name].show(animOptions, success, failure);
	};


	WizViewManager.prototype.hide = function (name, animOptions, success, failure) {
		if (!this.views[name]) {
			return this.throwError(failure, new Error('Hide Error with view name: ' + name + '. View does not exist'));
		}
	
		this.views[name].hide(animOptions, success, failure);
	};
 
 	WizViewManager.prototype.setLayout = function (name, animOptions, success, failure) {
		if (!this.views[name]) {
			return this.throwError(failure, new Error('Set Layout Error with view name: ' + name + '. View does not exist'));
		}
	
		this.views[name].setLayout(animOptions, success, failure);
 	};

  	WizViewManager.prototype.load = function (name, source, success, failure) {
		if (!this.views[name]) {
			return this.throwError(failure, new Error('Load Error with view name: ' + name + '. View does not exist'));
		}
	
		this.views[name].load(source, success, failure);
  	};

	WizViewManager.prototype.updateViewList = function (list) {
		
		// check for removed views
		for (var name in this.views) {
			if (list.indexOf(name) === -1) {
				delete this.views[name];
			}
		}
	
		// check for new views
		for (var i = 0; i < list.length; i++) {
			var name = list[i];
	
			if (!this.views[name]) {
				this.views[name] = new View(name);
			}
		}
		
	};


	// instantiate the wizViewManager (always named "mainView" in Cordova)
	window.wizViewManager = new WizViewManager('mainView');

}(window));
