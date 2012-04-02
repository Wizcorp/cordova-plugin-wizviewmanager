package jp.wizcorp.phonegap.plugin.WizViewManager;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;

import jp.wizcorp.android.shell.AndroidShellActivity;
import jp.wizcorp.android.shell.R;
import jp.wizcorp.phonegap.plugin.WizNavi.WizNaviPlugin;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.view.animation.Animation.AnimationListener;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.AbsoluteLayout.LayoutParams;

import com.phonegap.api.PhonegapActivity;
import com.phonegap.api.Plugin;
import com.phonegap.api.PluginResult;


/**
 * 
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file WizNaviBar Class use with phonegap WizNaviPlugin
 * @about Builder and controller for Wizard Navigations
 *
 */

public class WizWebView extends WebView  {
	
	
	private static Context mContext;

	// View Name Holder Oject
	public static JSONObject viewHolder = new JSONObject();
	
	static JSONArray notificationArray;
	static JSONObject notificationObject;
	
	// View Handler
	static Handler wizView_Handler;
	static Runnable show;
	static Runnable hide;
	
	private static Activity that;


	@SuppressWarnings("deprecation")
	public WizWebView(String viewName, JSONObject settings, final PhonegapActivity ctx) {
		super(ctx);
		// Constructor method
	

		mContext = ctx.getApplicationContext();
		that = ctx;

		
		Log.d("WizWebView", "[WizWebView] *************************************");
		Log.d("WizWebView", "[WizWebView] building - NEW Wizard View");
		Log.d("WizWebView", "[WizWebView] -> " + viewName);
		Log.d("WizWebView", "[WizWebView] *************************************");
		
		
		/*
		 *	Add View to topmost frame
		 */
		FrameLayout topMostFrame = (FrameLayout)((Activity) ctx).findViewById(R.id.mainView).getParent();

		
		/*
	     * 	WebView Params
	     */
		this.getSettings().setJavaScriptEnabled(true);
		this.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);
		
		
		String url;
		int _height = 0;
		int _width = 0;
		int _x = 0;
		int _y = 0;
		
		// the holder controls the width / height and padding
		// the webview Layout is always fill parent
		
		RelativeLayout.LayoutParams wizWebViewParams;
		wizWebViewParams = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT);
		this.setLayoutParams(wizWebViewParams);

		RelativeLayout.LayoutParams holderLayoutParams;
		
		// analyse settings object
		if (settings != null) {
			
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
					_height = LayoutParams.FILL_PARENT;
				}
								
			} else {
				// default
				_height = LayoutParams.FILL_PARENT;
			}
			
			if (settings.has("width")) {
				try {
					_width = settings.getInt("width");
				} catch (JSONException e) {
					// default
					_width = LayoutParams.FILL_PARENT;
				}
							
			} else {
				// default
				_width = LayoutParams.FILL_PARENT;
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
			
			
			holderLayoutParams = new RelativeLayout.LayoutParams(_width, _height);
			
		} else {
			// default to empty webview (no src specified in settings) and fill all
			holderLayoutParams = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT);

		}
		
		
		/*
		 *	Create Layout for the webview and attach it to topFrame, then attach the webview to the layout 
		 */
		RelativeLayout holderLayout = new RelativeLayout(ctx);
		holderLayout.setPadding(999+_x, _y, _x, _y);
		holderLayout.addView(this);
		
		topMostFrame.addView(holderLayout, 1, holderLayoutParams);
		
		
		
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
		    	
		    	// split url buy only 2 incase "://" occurs elsewhere (SHOULD be impossible because you string encoded right!?)
		    	urlArray = url.split(splitter,2);
		    	
		    	if (urlArray[0].equalsIgnoreCase("wizmessageview") ) {
		    		
		    		String[] msgData;
		    		splitter = "\\?";
		    		
		    		// split url buy only 2 again to make sure we only spit at the first "?"
		    		msgData = urlArray[1].split(splitter); 
		    		
			    	
		    		// target View = msgData[0] and message = msgData[1]
		    		
		    		// get webview list from View Manager
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
		    		
		    		// app will handle this url, dont change the browser url
					return true;	
		    		
		    		
		    	}
		    	
		    	
		    	// allow all other url requests
				return false;
		    }
		    
		    @Override
		    public void onPageFinished(WebView wView, String url) {
		    	String loadedCallbackId = WizViewManagerPlugin.getUpdatedCallbackId();
		    	
		    	PluginResult resulter = new PluginResult(com.phonegap.api.PluginResult.Status.OK);
		    	resulter.setKeepCallback(false);

		    	Plugin wizManagerPlugin = WizViewManagerPlugin.getPluginObj(); 
		    	
		    	wizManagerPlugin.success(resulter, loadedCallbackId);
		    
		    }
		    
		});

	} // ************ END CONSTRUCTOR **************
	

    
    public static void show() {
		
    	wizView_Handler.post(show);
	}

	public static void hide() {
		
		wizView_Handler.post(hide);
	}


}