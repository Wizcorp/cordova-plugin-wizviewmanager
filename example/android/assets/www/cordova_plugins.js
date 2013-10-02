cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
    {
        "file": "plugins/jp.wizcorp.phonegap.plugin.wizViewManagerPlugin/www/phonegap/plugin/wizViewManager/wizViewManager.js",
        "id": "jp.wizcorp.phonegap.plugin.wizViewManagerPlugin.wizViewManagerPlugin",
        "clobbers": [
            "window.wizViewManager"
        ]
    },
    {
        "file": "plugins/jp.wizcorp.phonegap.plugin.wizViewManagerPlugin/www/phonegap/plugin/wizViewMessenger/wizViewMessenger.js",
        "id": "jp.wizcorp.phonegap.plugin.wizViewManagerPlugin.wizViewMessenger",
        "clobbers": [
            "window.wizViewMessenger"
        ]
    }
]
});