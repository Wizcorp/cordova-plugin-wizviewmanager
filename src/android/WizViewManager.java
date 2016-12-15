/*
 *  __    __ _                  _         _                                                          
 * / / /\ \ (_)______ _ _ __ __| | /\   /(_) _____      __   /\/\   __ _ _ __   __ _  __ _  ___ _ __ 
 * \ \/  \/ / |_  / _` | '__/ _` | \ \ / / |/ _ \ \ /\ / /  /    \ / _` | '_ \ / _` |/ _` |/ _ \ '__|
 *  \  /\  /| |/ / (_| | | | (_| |  \ V /| |  __/\ V  V /  / /\/\ \ (_| | | | | (_| | (_| |  __/ |   
 *   \/  \/ |_/___\__,_|_|  \__,_|   \_/ |_|\___| \_/\_/   \/    \/\__,_|_| |_|\__,_|\__, |\___|_|   
 *                                                                                   |___/                                                                                              |___/                           |___/        
 * @author  Ally Ogilvie  
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2013
 * @file    - WizViewManager.java
 * @about   - Handle view and communication.
 */
package jp.wizcorp.wizviewmanager;

import android.view.ViewGroup;
import android.webkit.WebResourceResponse;
import android.widget.LinearLayout;
import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebSettings;

import java.io.ByteArrayInputStream;

public class WizViewManager extends CordovaPlugin {

    // The following files can be open natively by the WebView
    public static String[] whitelist = {
        ".txt", ".md",
        ".php", ".java", ".html", ".htm", ".xml", ".css", ".js",
        ".jpg", ".png", ".jpeg", ".gif", ".tif", "."
    };
    // The following files can be opened with the helper prefix in a WebView;
    // http://docs.google.com/a/wizcorp.jp/gview?embedded=true&url=
    public static String[] helperList = {
        ".docx", ".doc",
        ".xls", ".xlsx",
        ".ppt", ".pptx",
        ".pdf", ".pages",
        ".ai", ".psd",
        ".h", ".m", ".c", ".cc", ".cpp",
        ".webm", ".mpeg4", ".3gpp", ".mov", ".avi", ".mpegps", ".wmv", ".flv"
    };
    private String TAG = "WizViewManager";

    static JSONObject viewList = new JSONObject();
    static CordovaInterface _cordova;
    static CordovaWebView _webView;

    @Override
    public void initialize(CordovaInterface cordova, final CordovaWebView webView) {
        _cordova = cordova;
        _webView = webView;
        final View view = webView.getView();
        Log.d(TAG, "Initialize Plugin");
        // By default, get a pointer to mainView and add mainView to the viewList as it always exists (hold phonegap's view)
        if (!viewList.has("mainView")) {
            // Cordova view is not in the viewList so add it.
            try {
                viewList.put("mainView", view);
                // To avoid "method was called on thread 'JavaBridge'" error we use a runnable
                view.post(new Runnable() {
                    @Override
                    public void run() {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                            // Only for Kitkat and newer versions
                            webView.sendJavascript("window.name = 'mainView';");
                        } else {
                            webView.loadUrl("javascript:window.name = 'mainView';");
                        }
                    }
                });
            } catch (JSONException e) {
                // Error handle (this should never happen!)
                Log.e(TAG, "Critical error. Failed to retrieve Cordova's view");
            }
        }
        super.initialize(cordova, webView);
        view.post(new Runnable() {
            @Override
            public void run() {
                WebSettings settings;
                settings = ((WebView) view).getSettings();
                settings.setDomStorageEnabled(true);
                settings.setLoadWithOverviewMode(true);
                settings.setUseWideViewPort(true);
            }
        });
    }

    @android.annotation.TargetApi(11)
    public WebResourceResponse shouldInterceptRequest(String url) {
        ByteArrayInputStream stream = new ByteArrayInputStream(url.getBytes());
        this.onOverrideUrlLoading(url);
        return new WebResourceResponse("text/plain", "UTF-8", stream);
    }

    @Override
    public boolean onOverrideUrlLoading(String url) {

        Log.d(TAG, "[Override URL] ****** "+ url);

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
            JSONObject viewList = WizViewManager.getViews();

            if (viewList.has(msgData[1]) ) {

                WebView targetView;
                try {
                    targetView = (WebView) viewList.get(msgData[1]);

                    String data2send = msgData[2];

                    Log.d(TAG, "[wizMessage] targetView ****** is " + msgData[1] + " -> " + targetView + " with data -> " + data2send);
                    String jsString = "wizViewMessenger.__triggerMessageEvent(\"" + msgData[0] + "\", \"" + msgData[1] + "\", \"" + data2send + "\", \"" + msgData[3] + "\");";
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                        // Only for Kitkat and newer versions
                        targetView.evaluateJavascript(jsString, null);
                    } else {
                        targetView.loadUrl("javascript:" + jsString);
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
            JSONObject viewList = WizViewManager.getViews();

            if (viewList.has(msgData[0]) ) {

                WebView targetView;
                try {
                    targetView = (WebView) viewList.get(msgData[0]);

                    String data2send = msgData[1];
                    data2send = data2send.replace("'", "\\'");
                    Log.d(TAG, "[wizMessage] targetView ****** is " + msgData[0]+ " -> " + targetView + " with data -> "+data2send );
                    String jsString = "(wizMessageReceiver('" + data2send + "'))";
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                        // Only for Kitkat and newer versions
                        targetView.evaluateJavascript(jsString, null);
                    } else {
                        targetView.loadUrl("javascript:" + jsString);
                    }

                } catch (JSONException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
            }
            // app will handle this url, don't change the browser url
            return true;
        }

        return super.onOverrideUrlLoading(url);
    }

    /*
    @Override
    public void onPageFinished(WebView wView, String url) {
        WizViewManager.updateViewList();
    }
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        Log.d(TAG, "[action] ****** " + action );

        if (action.equals("createView")) {
            // Create a new view
            Log.d(TAG, "[createView] ****** " + args.toString() );

            final String viewName;
            final JSONObject settings;
            try {
                // Get view name
                viewName = args.getString(0);
                settings = args.optJSONObject(1);
                Log.d(TAG, "Create view with settings : " + settings);

            } catch (Exception e) {
                Log.e(TAG, "Exception: " + e);
                callbackContext.error("Cannot create view. Missing view name parameter");
                return true;
            }

            // Create a final link so we can run on UI thread
            Log.d(TAG, "list: " + viewList.names().toString());

            // Create link to callback
            final CallbackContext create_cb = callbackContext;

            cordova.getActivity().runOnUiThread(
                    new Runnable() {
                        @Override
                        public void run() {
                            WizWebView wizWebView = new WizWebView(viewName, settings, cordova.getActivity(), create_cb);
                            // Put our new View into viewList
                            try {
                                viewList.put(viewName, wizWebView);
                                updateViewList();
                            } catch (JSONException e) {
                                // Error handle
                                e.printStackTrace();
                            }
                        }
                    }
                    );

            // Wait for callback
            PluginResult res = new PluginResult(PluginResult.Status.NO_RESULT);
            res.setKeepCallback(true);
            callbackContext.sendPluginResult(res);

            // Clean up
            callbackContext = null;

            return true;

        } else if (action.equals("removeView")) {
            // TODO: Async callback
            // Remove a view from the application
            Log.d(TAG, "[removeView] ****** " + args.toString() );

            final String viewName;
            try {
                // Get view name
                viewName = args.getString(0);
            } catch (Exception e) {
                Log.e(TAG, "Cannot remove view. Missing view name parameter");
                callbackContext.error("Cannot remove view. Missing view name parameter");
                return true;
            }

            // Find WebView by this name and remove it
            if (viewList.has(viewName) ) {
                final WizWebView targetView = (WizWebView) viewList.get(viewName);

                cordova.getActivity().runOnUiThread(
                        new Runnable() {
                            @Override
                            public void run() {
                                ViewGroup viewGroup = (ViewGroup) targetView.getParent();
                                viewGroup.removeView(targetView);
                                viewGroup = null;
                            }
                        });

                viewList.remove(viewName);
                updateViewList();

                // Remove is running on a different thread, but for now assume view was removed
                callbackContext.success();
                        return true;
            } else {
                // Cannot find view
                Log.e(TAG, "Cannot remove view. View not found");
                callbackContext.error("Cannot remove view. View not found");
                return true;
            }

        } else if (action.equals("hideView")) {
            // TODO: Async callback
            // TODO: animations like iOS

            // Hide a particular view...
            Log.d(TAG, "[hideView] ****** " + args.toString() );

            final String viewName;

            // set defaults for animations
            long animDuration = 500;
            String animType = "none";

            try {
                viewName = args.getString(0);
                // analyse settings object
                try {

                    JSONObject settings = (JSONObject) args.get(1);

                    if (settings.has("animation")) {
                        JSONObject animation = settings.getJSONObject("animation");

                        if (animation.has("duration")) {
                            animDuration = (long)animation.getInt("duration");
                        }

                        if (animation.has("type")) {
                            animType = animation.getString("type");
                        }
                    }

                } catch (Exception e) {
                    // no settings, use default

                }

                // Find WebView by this name and hide it
                if (viewList.has(viewName) ) {

                    final WebView targetView = (WebView) viewList.get(viewName);

                    final long duration = animDuration;
                    final String type = animType;

                    cordova.getActivity().runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    /*
                                    hideCallbackId = callbackId;
                                    result = new PluginResult(Status.NO_RESULT);
                                    result.setKeepCallback(true);
                                     */

                                    // get current layout view then add our 999 buffer to bring back to view
                                    // final RelativeLayout layouter = (RelativeLayout) targetView.getParent();

                                    if (targetView.getPaddingLeft() == 0) {

                                        targetView.setVisibility(View.INVISIBLE);
                                        targetView.setPadding(999, 0, 0, 0);
                                        /*
                                        Animation animation;
                                        if (type.equals("none")) {

                                            targetView.setVisibility(View.INVISIBLE);
                                            // layouter.setPadding(layouter.getPaddingLeft()+999, 0, 0, 0);

                                        } else if (type.equals("fadeOut")) {

                                            animation = AnimationUtils.loadAnimation(cordova.getActivity(), R.anim.view_fadeout);
                                            animation.setFillAfter(true);
                                            animation.setFillEnabled(true);
                                            animation.setDuration((long) duration);
                                            animation.setAnimationListener(new AnimationListener() {

                                                public void onAnimationEnd(Animation animation) {
                                                    Log.d(TAG, "[hide - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());


                                                    layouter.setPadding(layouter.getPaddingLeft()+999, 0, 0, 0);
                                                    Log.d(TAG, "[hide - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());

                                                    targetView.setVisibility(View.INVISIBLE);
                                                    Log.d(TAG, "[hide - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());

                                                }

                                                public void onAnimationRepeat(Animation animation) {

                                                }

                                                public void onAnimationStart(Animation animation) {

                                                }

                                            });

                                            targetView.startAnimation(animation);

                                        } else if (type.equals("zoomOut")) {

                                            animation = AnimationUtils.loadAnimation(cordova.getActivity(), R.anim.view_zoomout);
                                            animation.setFillAfter(true);
                                            animation.setFillEnabled(true);
                                            animation.setDuration((long) duration);
                                            animation.setAnimationListener(new AnimationListener() {

                                                public void onAnimationEnd(Animation animation) {
                                                    targetView.setVisibility(View.INVISIBLE);
                                                    layouter.setPadding(layouter.getPaddingLeft()+999, 0, 0, 0);

                                                }

                                                public void onAnimationRepeat(Animation animation) {

                                                }

                                                public void onAnimationStart(Animation animation) {

                                                }

                                            });

                                            targetView.startAnimation(animation);
                                        }
                                         */

                                    } else {
                                        // already hidden, just callback
                                        Log.d(TAG, "[hide - view already invisible]");


                                    }
                                }
                            }
                            );

                    callbackContext.success();
                    return true;

                } else {
                    // Error handle
                    callbackContext.error("cannot find view");
                    return true;
                }

            } catch (JSONException e) {
                // Error handle
                callbackContext.error("missing view name parameter");
                return true;
            }

            // callbackContext.success();
            // return true;

        } else if (action.equals("showView")) {
            // TODO: Async callback
            // TODO: animations like iOS
            // Show a particular view...
            Log.d(TAG, "[showView] ****** " + args.toString() );

            String viewName;

            // Set defaults for animations
            long animDuration = 500;
            String animType = "none";

            try {
                viewName = args.getString(0);

                /*
                // Analyse settings object
                try {
                    JSONObject settings = (JSONObject) args.get(1);

                    if (settings.has("animation")) {
                        JSONObject animation = settings.getJSONObject("animation");

                        if (animation.has("duration")) {
                            animDuration = (long)animation.getInt("duration");
                        }

                        if (animation.has("type")) {
                            animType = animation.getString("type");
                        }
                    }

                } catch (Exception e) {
                    // No settings, use default
                    Log.d(TAG, "Do options set, using defaults");
                }
                 */

                // Find WebView by this name and show it
                if (viewList.has(viewName) ) {
                    Log.d(TAG, "Get WebView in view list");
                    final WebView targetView = (WebView) viewList.get(viewName);
                    Log.d(TAG, targetView.toString());
                    long duration = animDuration;

                    cordova.getActivity().runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    if (targetView.getVisibility() == View.INVISIBLE) {

                                        // Get current layout view then minus our 999 buffer to bring back to view
                                        // final RelativeLayout layouter = (RelativeLayout) targetView.getParent();
                                        targetView.getPaddingLeft();
                                        Log.d(TAG, "[show - targetView.getPaddingLeft()] ****** " + targetView.getPaddingLeft());

                                        if (targetView.getPaddingLeft() == 999) {
                                            /*
                                            Animation animation;

                                            if (animType.equals("none")) {

                                                Log.d(TAG, "[show - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());

                                                layouter.setPadding(layouter.getPaddingLeft()-999, 0, 0, 0);
                                                targetView.setVisibility(View.VISIBLE);

                                                Log.d(TAG, "[show - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());


                                            } else if (animType.equals("fadeIn")) {

                                                animation = AnimationUtils.loadAnimation(cordova.getActivity(), R.anim.view_fadein);
                                                animation.setFillAfter(true);
                                                animation.setFillEnabled(true);
                                                animation.setDuration((long) duration);

                                                animation.setAnimationListener(new AnimationListener() {

                                                    public void onAnimationEnd(Animation animation) {

                                                    }

                                                    public void onAnimationRepeat(Animation animation) {

                                                    }

                                                    public void onAnimationStart(Animation animation) {
                                                        layouter.setPadding(layouter.getPaddingLeft()-999, 0, 0, 0);
                                                        targetView.setVisibility(View.VISIBLE);
                                                    }

                                                });

                                                targetView.startAnimation(animation);

                                            } else if (animType.equals("zoomIn")) {

                                                animation = AnimationUtils.loadAnimation(cordova.getActivity(), R.anim.view_zoomin);
                                                animation.setFillAfter(true);
                                                animation.setFillEnabled(true);
                                                animation.setDuration((long) duration);

                                                animation.setAnimationListener(new AnimationListener() {

                                                    public void onAnimationEnd(Animation animation) {


                                                    }

                                                    public void onAnimationRepeat(Animation animation) {

                                                    }

                                                    public void onAnimationStart(Animation animation) {
                                                        layouter.setPadding(layouter.getPaddingLeft()-999, 0, 0, 0);
                                                        targetView.setVisibility(View.VISIBLE);
                                                    }

                                                });

                                                targetView.startAnimation(animation);

                                            }
                                             */
                                            // callbackContext.success();
                                            // return true;
                                            // No animations
                                            targetView.setVisibility(View.VISIBLE);
                                            targetView.setPadding(0, 0, 0, 0);
                                            Log.d(TAG, "[show - targetView.getPaddingLeft()] ****** " + targetView.getPaddingLeft());
                                        } else {
                                            // already shown, just callback
                                            Log.d(TAG, "[show - view already visible]");

                                        }
                                    }
                                }
                            }
                            );

                    callbackContext.success();
                    return true;

                } else {
                    // Error handle
                    Log.e(TAG, "Cannot show. Cannot find view");
                    callbackContext.error("Cannot show. Cannot find view");
                    return true;
                }

            } catch (JSONException e) {
                // Error handle
                Log.e(TAG, "Cannot show. Missing view name parameter");
                callbackContext.error("Cannot show. Missing view name parameter");
                return true;
            }

        } else if (action.equals("setLayout")) {

            try {
                String viewName = args.getString(0);
                final JSONObject options = args.getJSONObject(1);

                if (viewName.equals("mainView")) {
                    final View targetView = (View) viewList.get(viewName);

                    cordova.getActivity().runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    WizViewManager.setLayout(targetView, options);
                                }
                            }
                            );
                } else {
                    final WizWebView targetView = (WizWebView) viewList.get(viewName);

                    cordova.getActivity().runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    targetView.setLayout(options, null);
                                }
                            }
                            );
                }

            } catch (Exception e) {
                Log.e(TAG, "Error: " + e);
            }

            callbackContext.success();

            return true;

        } else if (action.equals("load")) {
            Log.d(TAG, "[load] ****** ");

            String viewName;
            try {
                viewName = args.getString(0);
            } catch (JSONException e) {
                Log.e(TAG, "Cannot load into view. Missing view name parameter");
                callbackContext.error("Cannot load into view. Missing view name parameter");
                return true;
            }

            // Find WebView by this name and show it
            if (viewList.has(viewName) ) {
                final WizWebView targetView = (WizWebView) viewList.get(viewName);
                JSONObject options = args.getJSONObject(1);

                if (options.has("src")) {
                    final String url = options.getString("src");
                    Log.d(TAG, "[load] url>> " + url);
                    final CallbackContext load_cb = callbackContext;
                    cordova.getActivity().runOnUiThread(
                            new Runnable() {
                                public void run() {
                                    targetView.load(url, load_cb);
                                }
                            }
                            );
                } else {
                    Log.e(TAG, "Cannot load into view. No source to load.");
                    callbackContext.error("Cannot load into view.  No source to load.");
                    return true;
                }

                // Wait for callback
                PluginResult res = new PluginResult(PluginResult.Status.NO_RESULT);
                res.setKeepCallback(true);
                callbackContext.sendPluginResult(res);

                // Clean up
                callbackContext = null;
                return true;

            } else {
                Log.e(TAG, "Cannot update view. Missing view name parameter");
                callbackContext.error("Cannot update view. Missing view name parameter");
                return true;
            }
        }
        return false;
    }

    public static JSONObject getViews() {
        return viewList;
    }

    public static void updateViewList() {
        WebView targetView = null;
        String jsString = "";
        try {
            // Build JS execution String form all view names in viewList
            targetView = (WebView) viewList.get("mainView");
            JSONArray viewListNameArray = viewList.names();
            jsString += "window.wizViewManager.updateViewList(" + viewListNameArray.toString() + "); ";
            Log.d("wizViewManager", "Execute JS: " + jsString);
            Log.d("wizViewManager", "Updated view list");
        } catch (JSONException ex) {
            return;
        }
        final WebView _targetView = targetView;
        final String _jsString = jsString;

        _cordova.getActivity().runOnUiThread(
                new Runnable() {
                    public void run() {
                        if (_targetView != null) {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                                // Only for Kitkat and newer versions
                                _targetView.evaluateJavascript(_jsString, null);
                            } else {
                                _targetView.loadUrl("javascript:" + _jsString);
                            }
                        }
                    }
                }
                );

        // Clean up references
        targetView = null;
        jsString = null;
    }

    public static void setLayout(View view, JSONObject settings) {

        Log.d("WizViewManager", "Setting up mainView layout...");
        Log.d("WizViewManager", view.toString());

        String url;
        // Size
        int _height = view.getHeight();
        int _width = view.getWidth();
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
                // default
                _height = ViewGroup.LayoutParams.MATCH_PARENT;
            }
        }

        if (settings.has("width")) {
            try {
                _width = settings.getInt("width");
            } catch (JSONException e) {
                // default
                _width = ViewGroup.LayoutParams.MATCH_PARENT;
            }
        }

        if (settings.has("x")) {
            try {
                _x = settings.getInt("x");
            } catch (JSONException e) {
                // default
                _x = 0;
            }
        }

        if (settings.has("y")) {
            try {
                _y = settings.getInt("y");
            } catch (JSONException e) {
                // default
                _y = 0;
            }
        }

        if (settings.has("left")) {
            try {
                _left = _x + settings.getInt("left");
                _width -= _left;
            } catch (JSONException e) {
                // default
                _left = _x;
            }
        }

        if (settings.has("right")) {
            try {
                _right = settings.getInt("right");
                _width += _right;
            } catch (JSONException e) {
                // default
                _right = 0;
            }
        }

        if (settings.has("top")) {
            try {
                _top = _y + settings.getInt("top");
            } catch (JSONException e) {
                // default
                _top = _y;
            }
        }
        if (settings.has("bottom")) {
            try {
                _bottom = settings.getInt("bottom") - _y;
            } catch (JSONException e) {
                // default
                _bottom = 0 - _y;
            }
        }
        /*
        ViewGroup.MarginLayoutParams marginParams = (ViewGroup.MarginLayoutParams) webView.getLayoutParams();
        Log.d("WizViewManager", marginParams.toString());
        marginParams.setMargins(_left, _top, _right, _bottom);

        webView.setLayoutParams(marginParams);
         */
        LinearLayout.LayoutParams layoutParams = (LinearLayout.LayoutParams) view.getLayoutParams();
        Log.d("WizViewManager", layoutParams.toString());
        layoutParams.setMargins(_left, _top, _right, _bottom);
        layoutParams.height = _height;
        layoutParams.width = _width;

        view.setLayoutParams(layoutParams);

        Log.d("WizViewManager", "new layout -> width: " + layoutParams.width + " - height: " + layoutParams.height + " - margins: " + layoutParams.leftMargin + "," + layoutParams.topMargin + "," + layoutParams.rightMargin + "," + layoutParams.bottomMargin);
    }
}
