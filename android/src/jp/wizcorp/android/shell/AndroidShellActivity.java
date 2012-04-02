package jp.wizcorp.android.shell;



import jp.wizcorp.phonegap.plugin.WizViewManager.WizViewManagerPlugin;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.Display;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.WebView;



import com.phonegap.DroidGap;



/**
 * 
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file AndroidShellActivity.java
 * @about Main Activity
 *
 */

public class AndroidShellActivity extends DroidGap {
	
	// Config Vars
	// ** If ad Id's are set to "null" requests will be switched off **
	private static int statsHeight 		= 0;										// Modify height of tooldbars (if modify, remember to edit images too), bar auto adapts to screen dpi
	private static int navHeight 		= 0;
	private Boolean startWithNavBar 	= true;										// Hide or show bottom bar on start up?
	private Boolean startWithStatBar 	= true;										// Hide or show top stats bar on start up?

	private String gameUrl 		= "file:///android_asset/www/index_game.html";
	
	
	
	
	
	
    /**
     * The SharedPreferences key for recording whether we initialized the
     * database.  If false, then we perform a RestoreTransactions request
     * to get all the purchases for this user.
     *     
     */

	
	// Vars
	public static int width = 0;
	public static int height = 0;

	
	// Views
	public static View html;
	public static RelativeLayout view;
	public static RelativeLayout mainView;

		
	static Activity that;
	

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        that 		= this;
        
        
        /*
	     * 	Reset Layouts (re-structure phonegap webview - enclose in relative layout)
	     */
        super.init();
		setContentView(R.layout.main);
		mainView = (RelativeLayout)findViewById(R.id.mainView);			// Holds Nav / Stat bars
		view = (RelativeLayout)findViewById(R.id.phonegap_container); 	// Holds PhoneGap

		
		/*
	     * 	Re-configure PhoneGap "appView" layout
	     */
        html = (View)super.appView.getParent();
        //html.setBackgroundColor(Color.parseColor("#212c39"));
        
        super.appView.setClipToPadding(true);
        view.setClipToPadding(true);
        view.addView(html, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));

        
        /*
	     * 	Splash settings
	     */
        appView.addJavascriptInterface(new AndroidShellSplashAddon(this, html), "SplashScreen");
        
        appView.enablePlatformNotifications();
        
        
        /*
	     * 	Boot URL
	     */
        super.loadUrl(gameUrl);
        
        
        /*
	     * 	Remove android system top bar
	     */
   	   		getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, 
   	   				WindowManager.LayoutParams.FLAG_FULLSCREEN | 
   	   				WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
        

        
   	   	/*
	     * 	Get device screen size
	     */
        Display display = ((WindowManager) getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay();
        width = display.getWidth(); 
        height = display.getHeight();
       
        // calculate bar heights
        statsHeight = (int) (height/8.74);
        navHeight	= (int)	(height/9.6);
        
        

        

        

        
        
        /*
		 *	Override url loading on WebViewClient  
		 */
        super.appView.setWebViewClient(new DroidGap.GapViewClient(this) {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
            	
    	    	Log.d("ShellActivity", "[GapViewClient] ****** "+ url);
    	    	
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
    						Log.d("ShellActivity", "[GapViewClient] targetView ****** is " + msgData[0]+ " -> " + targetView + " with data -> "+data2send );
    						targetView.loadUrl("javascript:(wizMessageReceiver('"+data2send+"'))");

    					} catch (JSONException e) {
    						e.printStackTrace();
    						Log.e("ShellActivity", "[GapViewClient] FAIL to get target view and load URL: "+e);
    					}
    	    			
    	    			
    					
    	    			
    	    		}
    	    		
    	    		// app will override this url == true
    				return true;	
    	    		
    	    		
    	    	}
            	
    	    	// everything else, do not override == false
                return false;
            }
        });
        


        


        
    } // ************ END MAIN ACTIVITY **************
    
    


	
	
	
	
	
	
	






	/*
	 *  Getters
	 */

	public static WebView getAppView() {
		// returns DroidGap.appView
		
		/*
			TODO:
			you may need to add your view id here
			it would be nice if this could be automated!
		
		*/
		
		WebView nWebView = (WebView) that.findViewById(0x64);
		return nWebView;
	}


	public static Activity getActivity() {
		// returns DroidGap context
		return that;
	}


	public static RelativeLayout getRLmainView() {
		// returns the Relative Layout view
		return mainView;
	}
	



}