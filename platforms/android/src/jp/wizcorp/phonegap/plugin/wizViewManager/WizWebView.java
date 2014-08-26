/*
 *  __    __ _                  _   __    __     _          _               
 * / / /\ \ (_)______ _ _ __ __| | / / /\ \ \___| |__/\   /(_) _____      __
 * \ \/  \/ / |_  / _` | '__/ _` | \ \/  \/ / _ \ '_ \ \ / / |/ _ \ \ /\ / /
 *  \  /\  /| |/ / (_| | | | (_| |  \  /\  /  __/ |_) \ V /| |  __/\ V  V / 
 *   \/  \/ |_/___\__,_|_|  \__,_|   \/  \/ \___|_.__/ \_/ |_|\___| \_/\_/  
 *
 * @author  Ally Ogilvie
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2013
 * @file    - WizViewManagerPlugin.java
 * @about   - Builder and controller for Wizard WebView Navigation
 */
package jp.wizcorp.phonegap.plugin.wizViewManager;

import android.app.Activity;
import android.content.res.AssetManager;
import android.graphics.Color;
import android.os.Build;
import android.view.Gravity;
import android.view.ViewGroup;
import android.webkit.MimeTypeMap;
import android.widget.RelativeLayout;
import org.apache.cordova.CallbackContext;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.util.Log;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;

@TargetApi(Build.VERSION_CODES.HONEYCOMB)
@SuppressLint("SetJavaScriptEnabled")
public class WizWebView extends WebView  {

    private String TAG = "WizWebView";
    private CallbackContext create_cb;
    private CallbackContext load_cb;
    private Context mContext;

    static final FrameLayout.LayoutParams COVER_SCREEN_GRAVITY_CENTER =
            new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    Gravity.CENTER);

    public WizWebView(String viewName, JSONObject settings, Context context, CallbackContext callbackContext) {
        // Constructor method
        super(context);

        mContext = context;

        Log.d("WizWebView", "[WizWebView] *************************************");
        Log.d("WizWebView", "[WizWebView] building - new Wizard View");
        Log.d("WizWebView", "[WizWebView] -> " + viewName);
        Log.d("WizWebView", "[WizWebView] *************************************");

        // Hold create callback and execute after page load
        this.create_cb = callbackContext;

        // Set invisible by default, developer MUST call show to see the view
        this.setVisibility(View.INVISIBLE);

        //  WizWebView Settings
        WebSettings webSettings = this.getSettings();

        webSettings.setJavaScriptEnabled(true);

        webSettings.setDomStorageEnabled(true);
        // Whether or not on-screen controls are displayed can be set with setDisplayZoomControls(boolean). 
        // The default is false.
        // The built-in mechanisms are the only currently supported zoom mechanisms, 
        // so it is recommended that this setting is always enabled.
        webSettings.setBuiltInZoomControls(true);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setUseWideViewPort(true);

        if (android.os.Build.VERSION.SDK_INT > android.os.Build.VERSION_CODES.ICE_CREAM_SANDWICH_MR1) {
            Level16Apis.enableUniversalAccess(webSettings);
        }

        this.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            // Only for Kitkat and newer versions
            this.evaluateJavascript("window.name = '" + viewName + "';", null);
        } else {
            this.loadUrl("javascript:window.name = '" + viewName + "';");
        }

        ViewGroup frame = (ViewGroup) ((Activity) context).findViewById(android.R.id.content);

        // Creating a new RelativeLayout fill its parent by default
        RelativeLayout.LayoutParams rlp = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.FILL_PARENT,
                RelativeLayout.LayoutParams.FILL_PARENT);

        // Default full screen
        frame.addView(this, rlp);

        this.setPadding(999, 0, 0, 0);

        // Set a transparent background
        this.setBackgroundColor(Color.TRANSPARENT);
        if (Build.VERSION.SDK_INT >= 11) this.setLayerType(WebView.LAYER_TYPE_SOFTWARE, null);

        // Override url loading on WebViewClient
        this.setWebViewClient(new WebViewClient () {
            @Override
            public boolean shouldOverrideUrlLoading(WebView wView, String url) {
                Log.d("WizWebView", "[WizWebView] ****** " + url);

                String[] urlArray;
                String splitter = "://";

                // Split url by only 2 in the event "://" occurs elsewhere (SHOULD be impossible because you string encoded right!?)
                urlArray = url.split(splitter,2);

                if (urlArray[0].equalsIgnoreCase("wizpostmessage")) {

                    String[] msgData;
                    splitter = "\\?";

                    // Split url by only 2 again to make sure we only spit at the first "?"
                    msgData = urlArray[1].split(splitter);
                    // target View = msgData[0] and message = msgData[1]
                    // Get webview list from View Manager
                    JSONObject viewList = WizViewManagerPlugin.getViews();

                    if (viewList.has(msgData[1]) ) {

                        WebView targetView;
                        try {
                            targetView = (WebView) viewList.get(msgData[1]);

                            // send data to mainView
                            String data2send = msgData[2];
                            // Log.d("WizWebView", "[wizMessage] targetView ****** is " + msgData[1] + " -> " + targetView + " with data -> " + data2send);
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                                // Only for Kitkat and newer versions
                                targetView.evaluateJavascript("wizViewMessenger.__triggerMessageEvent(\"" + msgData[0] + "\", \"" + msgData[1] + "\", \"" + data2send + "\", \"" + msgData[3] + "\");", null);
                            } else {
                                targetView.loadUrl("javascript:wizViewMessenger.__triggerMessageEvent(\"" + msgData[0] + "\", \"" + msgData[1] + "\", \"" + data2send + "\", \"" + msgData[3] + "\");");
                            }
                        } catch (JSONException e) {
                            // TODO Auto-generated catch block
                            e.printStackTrace();
                        }
                    }
                    // app will handle this url, don't change the browser url
                    return true;
                }

                if (urlArray[0].equalsIgnoreCase("wizmessageview") ) {

                    String[] msgData;
                    splitter = "\\?";

                    // Split url by only 2 again to make sure we only spit at the first "?"
                    msgData = urlArray[1].split(splitter);


                    // target View = msgData[0] and message = msgData[1]

                    // Get webview list from View Manager
                    JSONObject viewList = WizViewManagerPlugin.getViews();

                    if (viewList.has(msgData[0])) {

                        WebView targetView;
                        try {
                            targetView = (WebView) viewList.get(msgData[0]);

                            // send data to mainView
                            String data2send = msgData[1];
                            data2send = data2send.replace("'", "\\'");
                            // Log.d(TAG, "[wizMessage] targetView ****** is " + msgData[0] + " -> " + targetView + " with data -> " + data2send);
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                                // Only for Kitkat and newer versions
                                targetView.evaluateJavascript("wizMessageReceiver('" + data2send + "');", null);
                            } else {
                                targetView.loadUrl("javascript:(wizMessageReceiver('" + data2send + "'))");
                            }
                        } catch (JSONException e) {
                            // TODO Auto-generated catch block
                            e.printStackTrace();
                        }
                    }
                    // app will handle this url, don't change the browser url
                    return true;
                }
                // allow all other url requests
                return false;
            }

            @Override
            public void onPageFinished(WebView wView, String url) {

                WizViewManagerPlugin.updateViewList();

                // Push wizViewMessenger

                String jsString = "var WizViewMessenger = function () {};\n" +
                        "WizViewMessenger.prototype.postMessage = function (message, targetView) { \n" +
                        "    var type;\n" +
                        "    if (Object.prototype.toString.call(message) === \"[object Array]\") {\n" +
                        "        type = \"Array\";\n" +
                        "        message = JSON.stringify(message);\n" +
                        "    } else if (Object.prototype.toString.call(message) === \"[object String]\") {\n" +
                        "        type = \"String\";\n" +
                        "    } else if (Object.prototype.toString.call(message) === \"[object Number]\") {\n" +
                        "        type = \"Number\";\n" +
                        "        message = JSON.stringify(message);\n" +
                        "    } else if (Object.prototype.toString.call(message) === \"[object Boolean]\") {\n" +
                        "        type = \"Boolean\";\n" +
                        "        message = message.toString();\n" +
                        "    } else if (Object.prototype.toString.call(message) === \"[object Function]\") {\n" +
                        "        type = \"Function\";\n" +
                        "        message = message.toString();\n" +
                        "    } else if (Object.prototype.toString.call(message) === \"[object Object]\") {\n" +
                        "        type = \"Object\";\n" +
                        "        message = JSON.stringify(message);\n" +
                        "    } else {\n" +
                        "    console.error(\"WizViewMessenger posted unknown type!\");\n" +
                        "        return;\n" +
                        "    }\n" +
                        "    \n" +
                        "\tvar iframe = document.createElement('IFRAME');\n" +
                        "\tiframe.setAttribute('src', 'wizPostMessage://'+ window.encodeURIComponent(window.name) + '?' + window.encodeURIComponent(targetView) + '?' + window.encodeURIComponent(message) + '?' + type );\n" +
                        "\tsetTimeout(function () {" +
                        "\tdocument.documentElement.appendChild(iframe);\n" +
                        "\tiframe.parentNode.removeChild(iframe);\n" +
                        "\tiframe = null;\t\t\n" +
                        "\t}, 1);" +
                        "};\n" +
                        "    \n" +
                        "WizViewMessenger.prototype.__triggerMessageEvent = function (origin, target, data, type) { \n" +
                        "    origin = decodeURIComponent(origin);\n" +
                        "    target = decodeURIComponent(target);\n" +
                        "    data = decodeURIComponent(data);\n" +
                        "    if (type === \"Array\") {\n" +
                        "        data = JSON.parse(data);\n" +
                        "    } else if (type === \"String\") {\n" +
                        "        // Stringy String String\n" +
                        "    } else if (type === \"Number\") {\n" +
                        "        data = JSON.parse(data);\n" +
                        "    } else if (type === \"Boolean\") {\n" +
                        "        data = Boolean(data);\n" +
                        "    } else if (type === \"Function\") {\n" +
                        "    } else if (type === \"Object\") {\n" +
                        "        data = JSON.parse(data);\n" +
                        "    } else {\n" +
                        "    \tconsole.error(\"Message Event received unknown type!\");\n" +
                        "        return;\n" +
                        "    }\n" +
                        "\t\n" +
                        "\tvar event = document.createEvent(\"HTMLEvents\");\n" +
                        "\tevent.initEvent(\"message\", true, true);\n" +
                        "\tevent.eventName = \"message\";\n" +
                        "\tevent.memo = { };\n" +
                        "\tevent.origin = origin;\n" +
                        "\tevent.source = target;\n" +
                        "\tevent.data = data;\n" +
                        "\tdispatchEvent(event);\n" +
                        "};\n" +
                        "\n" +
                        "window.wizViewMessenger = new WizViewMessenger();";

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                    // Only for Kitkat and newer versions
                    wView.evaluateJavascript(jsString, null);
                } else {
                    wView.loadUrl("javascript:" + jsString);
                }

                if (create_cb != null) {
                    create_cb.success();
                    Log.d(TAG, "View created and loaded");
                    // Callback used, don't call it again.
                    create_cb = null;
                }

                if (load_cb != null) {
                    load_cb.success();
                    Log.d(TAG, "View finished load");
                    // Callback used, don't call it again.
                    load_cb = null;
                }
            }

            public void onReceivedError(WebView view, int errorCod, String description, String failingUrl) {
                Log.e(TAG, "Error: Cannot load " + failingUrl + " \n Reason: " + description);
                if (create_cb != null) {
                    create_cb.error(description);
                    // Callback used, don't call it again.
                    create_cb = null;
                }
            }
        });

        // Analyse settings object
        if (settings != null) {
            this.setLayout(settings, create_cb);
        } else {
            // Apply Defaults
            this.setLayoutParams(COVER_SCREEN_GRAVITY_CENTER);
        }

        Log.d(TAG, "Create complete");
    } // ************ END CONSTRUCTOR **************

    public void setLayout(JSONObject settings, CallbackContext callback) {
        Log.d(TAG, "Setting up layout...");

        String url;

        // Set default settings to max screen
        ViewGroup parent = (ViewGroup) this.getParent();

        // Size
        int _parentHeight = parent.getHeight();
        int _parentWidth = parent.getWidth();
        int _height = _parentHeight;
        int _width = _parentWidth;

        // Margins
        int _x = 0;
        int _y = 0;
        int _top = 0;
        int _bottom = 0;
        int _right = 0;
        int _left = 0;

        if (settings.has("height")) {
            try {
                _height = settings.getInt("height");
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'height' in settings");
            }
        }

        if (settings.has("width")) {
            try {
                _width = settings.getInt("width");
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'width' in settings");
            }
        }

        if (settings.has("x")) {
            try {
                _x = settings.getInt("x");
                _left = _x;
                _width = _width + _x;
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'x' in settings");
            }
        }

        if (settings.has("y")) {
            try {
                _y = settings.getInt("y");
                _top = _y;
                _height = _height + _y;
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'y' in settings");
            }
        }

        if (settings.has("left")) {
            try {
                _left = _left + settings.getInt("left");
                _width -= _left;
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'left' in settings");
            }
        } else {
            // default
            if (_x != 0) {
                _left = _x;
            }
        }

        if (settings.has("right")) {
            try {
                _right = settings.getInt("right");
                _width = _width - _right;
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'right' in settings");
            }
        }

        if (settings.has("top")) {
            try {
                _top = _top + settings.getInt("top");
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'top' in settings");
            }
        } else {
            // default
            if (_y != 0) {
                _top = _y;
            }
        }

        if (settings.has("bottom")) {
            try {
                _top = _top + _parentHeight - _height - settings.getInt("bottom");
                _bottom = - settings.getInt("bottom");
            } catch (JSONException e) {
                // ignore
                Log.e(TAG, "Error obtaining 'bottom' in settings");
            }
        }

        FrameLayout.LayoutParams newLayoutParams = (FrameLayout.LayoutParams) this.getLayoutParams();
        newLayoutParams.setMargins(_left, _top, _right, _bottom);
        newLayoutParams.height = _height;
        newLayoutParams.width = _width;

        this.setLayoutParams(newLayoutParams);

        Log.d(TAG, "new layout -> width: " + newLayoutParams.width + " - height: " + newLayoutParams.height + " - margins: " + newLayoutParams.leftMargin + "," + newLayoutParams.topMargin + "," + newLayoutParams.rightMargin + "," + newLayoutParams.bottomMargin);

        if (settings.has("src")) {
            try {
                url = settings.getString("src");
                load(url, callback);
            } catch (JSONException e) {
                // default
                // nothing to load
                Log.e(TAG, "Loading source from settings exception : " + e);
            }
        } else {
            Log.d(TAG, "No source to load");
        }
    }

    public void load(String source, CallbackContext callbackContext) {
        // Link up our callback
        load_cb = callbackContext;

        // Check source extension
        try {
            URL url = new URL(source);    // Check for the protocol
            url.toURI();                  // Extra checking required for validation of URI

            // If we did not fall out here then source is a valid URI, check extension
            if (url.getPath().length() > 0) {
                // Not loading a straight domain, check extension of non-domain path
                String ext = MimeTypeMap.getFileExtensionFromUrl(url.getPath());
                Log.d(TAG, "URL ext: " + ext);
                if (validateExtension("." + ext)) {
                    // Load this
                    this.loadUrl(source);
                } else {
                    // Check if file type is in the helperList
                    if (requiresHelper("." + ext)) {
                        // Load this
                        this.loadUrl("http://docs.google.com/gview?embedded=true&url=" + source);
                    } else {
                        // Not valid extension in whitelist and cannot be helped
                        Log.e(TAG, "Not a valid file extension!");
                        if (load_cb != null) {
                            load_cb.error("Not a valid file extension.");
                            load_cb = null;
                        }
                    }
                }
                return;

            } else {
                // URL has no path, for example - http://google.com
                Log.d(TAG, "load URL: " + source);
                this.loadUrl(source);
            }

        } catch (MalformedURLException ex1) {
            // Missing protocol, assume local file

            // Check cache for latest file
            File cache = mContext.getApplicationContext().getCacheDir();
            File file = new File(cache.getAbsolutePath() + "/" + source);
            if (file.exists()) {
                // load it
                Log.d(TAG, "load: " + "file:///" + cache.getAbsolutePath() + "/" + source);
                source = ("file:///" + cache.getAbsolutePath() + "/" + source);
            } else {
                // Check file exists in bundle assets
                AssetManager mg = mContext.getResources().getAssets();
                try {
                    mg.open("www/" + source);
                    Log.d(TAG, "load: file:///android_asset/www/" + source);
                    source = "file:///android_asset/www/" + source;
                } catch (IOException ex) {
                    // Not in bundle assets. Try full path
                    file = new File(source);
                    if (file.exists()) {
                        Log.d(TAG, "load: file:///" + source);
                        source = "file:///" + source;
                        file = null;
                    } else {
                        // File cannot be found
                        Log.e(TAG, "File: " + source + " cannot be found!");
                        if (load_cb != null) {
                            load_cb.error("File: " + source + " cannot be found!");
                            load_cb = null;
                        }
                        return;
                    }
                }
            }
            this.loadUrl(source);
        } catch (URISyntaxException ex2) {
            Log.e(TAG, "URISyntaxException loading: file://" + source);
            if (load_cb != null) {
                load_cb.error("URISyntaxException loading: file://" + source);
                load_cb = null;
            }
        }
    }

    private boolean validateExtension(String candidate) {
        for (String s: WizViewManagerPlugin.whitelist) {
            // Check extension exists in whitelist
            if (s.equalsIgnoreCase(candidate)) {
                return true;
            }
        }
        return false;
    }

    private boolean requiresHelper(String candidate) {
        for (String s: WizViewManagerPlugin.helperList) {
            // Check extension exists in helperList
            if (s.equalsIgnoreCase(candidate)) {
                return true;
            }
        }
        return false;
    }

    @TargetApi(16)
    private static class Level16Apis {
        static void enableUniversalAccess(WebSettings settings) {
            settings.setAllowUniversalAccessFromFileURLs(true);
        }
    }
}

