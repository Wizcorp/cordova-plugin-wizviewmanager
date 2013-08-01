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

import android.graphics.Color;
import android.os.Build;
import android.view.Gravity;
import android.view.ViewGroup;
import org.apache.cordova.api.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;

import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;

@SuppressLint("SetJavaScriptEnabled")
public class WizWebView extends WebView  {

	private String TAG = "WizWebView";
    private CallbackContext create_cb;
    private CallbackContext load_cb;

    static final FrameLayout.LayoutParams COVER_SCREEN_GRAVITY_CENTER =
            new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    Gravity.CENTER);

	public WizWebView(String viewName, JSONObject settings, final ViewGroup parentView, Context context, CallbackContext callbackContext) {
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

        // Default full screen
        parentView.addView(this, COVER_SCREEN_GRAVITY_CENTER);

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
                            Log.d("WizWebView", "[GapViewClient] targetView ****** is " + msgData[0]+ " -> " + targetView + " with data -> "+data2send );
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
        // Size
        int _height = this.getHeight();
        int _width = this.getWidth();
        // Margins
        int _x = 0;
        int _y = 0;
        int _top = 0;
        int _bottom = 0;

        if (settings.has("src")) {
            try {
                url = settings.getString("src");
                this.loadUrl(url);
            } catch (JSONException e) {
                // default
                // nothing to load
            }
        }

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

        if (settings.has("top")) {
            try {
                _top = settings.getInt("top");
            } catch (JSONException e) {
                // default
                _top = 0;
            }
        }
        if (settings.has("bottom")) {
            try {
                _top = settings.getInt("top");
            } catch (JSONException e) {
                // default
                _bottom = 0;
            }
        }

        ViewGroup.MarginLayoutParams params = (MarginLayoutParams) this.getLayoutParams();
        params.setMargins(_x, _y, _top, _bottom);

        this.setLayoutParams(params);

        ViewGroup.LayoutParams layoutParams = (ViewGroup.LayoutParams) this.getLayoutParams();
        layoutParams.height = _height;
        layoutParams.width = _width;

        this.setLayoutParams(layoutParams);

        Log.d(TAG, "new layout -> width: " + layoutParams.width + " - height: " + layoutParams.height + " - margins: " + params.leftMargin + "," + params.topMargin + "," + params.rightMargin + "," + params.bottomMargin);
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