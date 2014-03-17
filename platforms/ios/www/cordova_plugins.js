cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
    {
        "file": "phonegap/plugin/wizViewManager/wizViewManager.js",
        "id": "jp.wizcorp.phonegap.plugin.wizViewManagerPlugin",
        "clobbers": [
            "window.wizViewManager"
        ]
    },
    {
        "file": "phonegap/plugin/wizViewManager/wizViewMessenger.js",
        "id": "jp.wizcorp.phonegap.plugin.wizViewManagerPlugin.wizViewMessenger",
        "clobbers": [
            "window.wizViewMessenger"
        ]
    }
];
module.exports.metadata = 
// TOP OF METADATA
{}
// BOTTOM OF METADATA
});