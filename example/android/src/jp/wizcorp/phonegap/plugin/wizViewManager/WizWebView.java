/*
 *  __    __ _                  _   __    __     _          _               
 * / / /\ \ (_)______ _ _ __ __| | / / /\ \ \___| |__/\   /(_) _____      __
 * \ \/  \/ / |_  / _` | '__/ _` | \ \/  \/ / _ \ '_ \ \ / / |/ _ \ \ /\ / /
 *  \  /\  /| |/ / (_| | | | (_| |  \  /\  /  __/ |_) \ V /| |  __/\ V  V / 
 *   \/  \/ |_/___\__,_|_|  \__,_|   \/  \/ \___|_.__/ \_/ |_|\___| \_/\_/  
 *                                                                                                                                                             |___/                                                                                              |___/                           |___/        
 * @author 	Ally Ogilvie  
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2013
 * @file	- WizViewManagerPlugin.java
 * @about	- Builder and controller for Wizard WebView Navigations
*/
package jp.wizcorp.phonegap.plugin.wizViewManager;

import android.app.Activity;
import android.graphics.Color;
import android.os.Build;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import org.apache.cordova.api.CallbackContext;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;

@SuppressLint("SetJavaScriptEnabled")
public class WizWebView extends WebView  {

	private String TAG = "WizWebView";
    private CallbackContext create_cb;
    private CallbackContext load_cb;

    /*
    static final FrameLayout.LayoutParams COVER_SCREEN_GRAVITY_CENTER =

            new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    Gravity.CENTER);
                    */

	public WizWebView(String viewName, JSONObject settings, Context context, CallbackContext callbackContext) {
        // Constructor method
        super(context);

		Log.d("WizWebView", "[WizWebView] *************************************");
		Log.d("WizWebView", "[WizWebView] building - new Wizard View");
		Log.d("WizWebView", "[WizWebView] -> " + viewName);
		Log.d("WizWebView", "[WizWebView] *************************************");

        // Hold create callback and execute after page load
        this.create_cb = callbackContext;

        // Set invisible by default, developer MUST call show to see the view
        this.setVisibility(View.INVISIBLE);

        // 	WizWebView Settings
        this.getSettings().setJavaScriptEnabled(true);
        this.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);


        ViewGroup frame = (ViewGroup) ((Activity) context).findViewById(android.R.id.content);

        // Creating a new RelativeLayout fill its parent by default
        RelativeLayout.LayoutParams rlp = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.FILL_PARENT,
                RelativeLayout.LayoutParams.FILL_PARENT);

        // Default full screen
        frame.addView(this, rlp);

        // Set a transparent background
        this.setBackgroundColor(Color.TRANSPARENT);
        if (Build.VERSION.SDK_INT >= 11) this.setLayerType(WebView.LAYER_TYPE_SOFTWARE, null);

        /*
		 *	Override url loading on WebViewClient
		 */
        this.setWebViewClient(new WebViewClient(){
            @Override
            public boolean shouldOverrideUrlLoading(WebView wView, String url)
            {
                Log.d("WizWebView", "[WizWebView] ****** "+ url);

                String[] urlArray;
                String splitter = "://";

                // Split url by only 2 in the event "://" occurs elsewhere (SHOULD be impossible because you string encoded right!?)
                urlArray = url.split(splitter,2);

                if (urlArray[0].equalsIgnoreCase("wizmessageview") ) {

                    String[] msgData;
                    splitter = "\\?";

                    // Split url by only 2 again to make sure we only spit at the first "?"
                    msgData = urlArray[1].split(splitter);


                    // target View = msgData[0] and message = msgData[1]

                    // Get webview list from View Manager
                    JSONObject viewList = WizViewManagerPlugin.getViews();

                    if (viewList.has(msgData[0]) ) {

                        WebView targetView;
                        try {
                            targetView = (WebView) viewList.get(msgData[0]);

                            // send data to mainView
                            String data2send = msgData[1];
                            data2send = data2send.replace("'", "\\'");
                            Log.d("WizWebView", "[wizMessage] targetView ****** is " + msgData[0]+ " -> " + targetView + " with data -> "+data2send );
                            targetView.loadUrl("javascript:(wizMessageReceiver('"+data2send+"'))");

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
        });

		// Analyse settings object
		if (settings != null) {
            this.setLayout(settings);
        }

		Log.d(TAG, "Create complete");
	} // ************ END CONSTRUCTOR **************

    public void setLayout(JSONObject settings) {
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
                this.loadUrl(url);
            } catch (JSONException e) {
                // default
                // nothing to load
                Log.e(TAG, "Loading source from settings exception : " + e);
            }
        } else {
            Log.e(TAG, "No source to load");
        }
    }

    public void load(String source, CallbackContext callbackContext) {
        // Link up our callback
        load_cb = callbackContext;

        // Check source
        try {
            URL u = new URL(source);    // Check for the protocol
            u.toURI();                  // Extra checking required for validation of URI

            // If we did not fall out here then source is a valid URI
            Log.d(TAG, "load URL: " + source);
            this.loadUrl(source);
        } catch (MalformedURLException ex1) {
            // Missing protocol
            Log.d(TAG, "load file://" + source);
            this.loadUrl("file://" + source);
        } catch (URISyntaxException ex2) {
            Log.d(TAG, "load file://" + source);
            this.loadUrl("file://" + source);
        }
    }
}