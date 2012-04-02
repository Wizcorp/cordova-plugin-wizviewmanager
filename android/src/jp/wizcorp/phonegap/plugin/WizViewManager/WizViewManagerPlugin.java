package jp.wizcorp.phonegap.plugin.WizViewManager;

import jp.wizcorp.android.shell.AndroidShellActivity;
import jp.wizcorp.android.shell.R;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.animation.Animation;
import android.view.animation.Animation.AnimationListener;
import android.view.animation.AnimationUtils;
import android.view.ViewParent;
import android.webkit.WebView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import com.phonegap.api.Plugin;
import com.phonegap.api.PluginResult;
import com.phonegap.api.PluginResult.Status;

/**
 * 
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2012
 * @file WizViewManagerPlugin for PhoneGap
 * @about Handle Popup UIViews and communtications.
 *
 */
public class WizViewManagerPlugin extends Plugin {

	/*
	 * 
	 * JavaScript Usage ->
	 * viewName - string type - name of the view to create
	 * s is success callback
	 * f is fail callback
	 * 
	 * var wizViewManager = { 
	 * 
	 * 		createView: function(viewName,s,f) {
	 *			return PhoneGap.exec( s, f, 'wizViewManager', 'createView', [viewName] );	
	 *		},
	 * 
	 * 
	 * }
	 * 
	 * example call
	 * 
	 * 	function myFunction() {
	 *   	wizViewManager.createView(
	 *   		"myViewName" ,
	 *			function(){console.log("[PHONEGAP //////////////] wizViewManager create - success")}, 
	 *			function(){console.log("[PHONEGAP //////////////] wizViewManager create - fail")}
	 *		);
	 * 
	 * 
	 * 
	 * 
	 */
	
	JSONObject returnObj;
	JSONArray returnArr;
	
	static JSONObject viewList = new JSONObject();
	
	static Plugin thisPlugin;
	
	static String updateCallbackId;
	static String showCallbackId;
	static String hideCallbackId;
	
	@Override
	public PluginResult execute(String action, JSONArray data, String callbackId)  {
		
		PluginResult result = null;
		thisPlugin = this;
		
		
		
		
		
		// by default, get a pointer to mainView and add mainView to the viewList as it always exists (hold phonegap)
		try {
			viewList.put("mainView", AndroidShellActivity.getAppView());
			Log.d("WizViewManagerPlugin", "AppView ****** " +AndroidShellActivity.getAppView());
		} catch (JSONException e) {
			// Error handle
			result = new PluginResult(Status.ERROR, "Failed to retrieve phonegap mainView");
			return result;
		}
		
		
		
		
		
		if (action.equals("createView")) {
			// create a new view
			Log.d("WizViewManagerPlugin", "[createView] ****** " + data.toString() );

			try {
				
				// get view name
				final String viewName = data.getString(0);
				
				JSONObject settings;
				
				/*
				Object checker = data.opt(1);
				if (checker != null) {
					// there is a settings object so get it
					settings = data.getJSONObject(1);
				}
				*/
				
				
				final JSONObject finalSettings = null;
				
				Activity mAct = AndroidShellActivity.getActivity();
				
				mAct.runOnUiThread(
		            new Runnable() {
		                public void run() {
		                	WizWebView newWebView = new WizWebView(viewName, finalSettings, ctx);
		                	
		                	// set invisible after create. 
		                	// MUST call show to see the view
		                	
		                	newWebView.setVisibility(View.INVISIBLE);
		                	
		                	// put our new View into list
		    				try {
								viewList.put(viewName, newWebView);
							} catch (JSONException e) {
								// Error handle
								e.printStackTrace();
							}
		                }
		            }
		        );
				
				result = new PluginResult(Status.OK);
			} catch (JSONException e1) {
				result = new PluginResult(Status.ERROR, "missing view name parameter");
			}
			
		} else if (action.equals("hideView")) {
			// Hide a particular view...
			Log.d("WizViewManagerPlugin", "[hideView] ****** " + data.toString() );
			
			String viewName;
			
			// set defaults for animations
			long animDuration = 500;
			String animType = "none";
			
			try {
				viewName = data.getString(0);
				
				// analyse settings object
				try {
					
					JSONObject settings = (JSONObject) data.get(1);
									
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
				
				// find webview by this name and hide it
				if (viewList.has(viewName) ) {
					
					final WebView targetView = (WebView) viewList.get(viewName);
					final long duration = animDuration;
					final String type = animType;
					
					if (targetView.getVisibility() == View.VISIBLE) {
/*
						hideCallbackId = callbackId;
						result = new PluginResult(Status.NO_RESULT);
						result.setKeepCallback(true);
*/
						
						Activity mAct = AndroidShellActivity.getActivity();
						mAct.runOnUiThread(
				            new Runnable() {
				                public void run() {
				                	// get current layout view then add our 999 buffer to bring back to view
				                	final RelativeLayout layouter = (RelativeLayout) targetView.getParent();
									
				                	
				                	if (layouter.getPaddingLeft() == 0) {

										Animation animation;
										if (type.equals("none")) {

						                	targetView.setVisibility(View.INVISIBLE);
						                	layouter.setPadding(layouter.getPaddingLeft()+999, 0, 0, 0);
						                	

										} else if (type.equals("fadeOut")) {
											
											animation = AnimationUtils.loadAnimation(ctx, R.anim.view_fadeout);
											animation.setFillAfter(true);
											animation.setFillEnabled(true);
											animation.setDuration((long) duration);
									     	animation.setAnimationListener(new AnimationListener() {
									     	 
	
												@Override
												public void onAnimationEnd(Animation animation) {
								                	Log.d("WizViewManagerPlugin", "[hide - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());


								                	layouter.setPadding(layouter.getPaddingLeft()+999, 0, 0, 0);
								                	Log.d("WizViewManagerPlugin", "[hide - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());

													targetView.setVisibility(View.INVISIBLE);
								                	Log.d("WizViewManagerPlugin", "[hide - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());


	
												}
	
												@Override
												public void onAnimationRepeat(Animation animation) {
													
												}
	
												@Override
												public void onAnimationStart(Animation animation) {
													
												}
									     	
									     	});
	
									     	targetView.startAnimation(animation);
									     	
										} else if (type.equals("zoomOut")) {
											
											animation = AnimationUtils.loadAnimation(ctx, R.anim.view_zoomout);
											animation.setFillAfter(true);
											animation.setFillEnabled(true);
											animation.setDuration((long) duration);
									     	animation.setAnimationListener(new AnimationListener() {
									     	 
	
												@Override
												public void onAnimationEnd(Animation animation) {
													targetView.setVisibility(View.INVISIBLE);
								                	layouter.setPadding(layouter.getPaddingLeft()+999, 0, 0, 0);
	
												}
	
												@Override
												public void onAnimationRepeat(Animation animation) {
													
												}
	
												@Override
												public void onAnimationStart(Animation animation) {
													
												}
									     	
									     	});
	
									     	targetView.startAnimation(animation);
										}
									
				                	}
				                	

							     	// WizViewManagerPlugin.callbackHide();

				                }
				            }
				        );
						
						result = new PluginResult(Status.OK);

					} else {
						// already hidden, just callback
						Log.d("WizViewManagerPlugin", "[hide - view already invisible]");
						result = new PluginResult(Status.OK);
					}
					
					
					
				} else {
					// Error handle
					result = new PluginResult(Status.ERROR, "cannot find view");
				}
				
			} catch (JSONException e) {
				// Error handle
				result = new PluginResult(Status.ERROR, "missing view name parameter");
			}
			
			result = new PluginResult(Status.OK);
	
		} else if (action.equals("showView")) {
			// Show a particular view...
			Log.d("WizViewManagerPlugin", "[showView] ****** " + data.toString() );
			
			String viewName;
			
			// set defaults for animations
			long animDuration = 500;
			String animType = "none";
			
			try {
				viewName = data.getString(0);
				
				// analyse settings object
				try {
					JSONObject settings = (JSONObject) data.get(1);
									
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

					
				
				
				// find webview by this name and show it
				if (viewList.has(viewName) ) {
					
					final WebView targetView = (WebView) viewList.get(viewName);
					final long duration = animDuration;
					final String type = animType;
					
					if (targetView.getVisibility() == View.INVISIBLE) {
						/*
						showCallbackId = callbackId;
						result = new PluginResult(Status.NO_RESULT);
						result.setKeepCallback(true);
						*/
						Activity mAct = AndroidShellActivity.getActivity();
						mAct.runOnUiThread(
				            new Runnable() {
				                public void run() {
				                	// get current layout view then minus our 999 buffer to bring back to view
				                	final RelativeLayout layouter = (RelativeLayout) targetView.getParent();
				                	Log.d("WizViewManagerPlugin", "[show - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());
				                	
				                	if (layouter.getPaddingLeft() == 999) {
					                										
										
										Animation animation;
										
										if (type.equals("none")) {
											
						                	Log.d("WizViewManagerPlugin", "[show - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());

						                	
											layouter.setPadding(layouter.getPaddingLeft()-999, 0, 0, 0);
											targetView.setVisibility(View.VISIBLE);
											
						                	Log.d("WizViewManagerPlugin", "[show - layouter.getPaddingLeft()] ****** " + layouter.getPaddingLeft());

											
										} else if (type.equals("fadeIn")) {
											
											animation = AnimationUtils.loadAnimation(ctx, R.anim.view_fadein);
											animation.setFillAfter(true);
											animation.setFillEnabled(true);
											animation.setDuration((long) duration);
											
											animation.setAnimationListener(new AnimationListener() {
										     	 
												
												@Override
												public void onAnimationEnd(Animation animation) {
													
	
												}
	
												@Override
												public void onAnimationRepeat(Animation animation) {
													
												}
	
												@Override
												public void onAnimationStart(Animation animation) {
													layouter.setPadding(layouter.getPaddingLeft()-999, 0, 0, 0);
													targetView.setVisibility(View.VISIBLE);
												}
									     	
									     	});
											
									     	targetView.startAnimation(animation);
									     	
										} else if (type.equals("zoomIn")) {
											
											animation = AnimationUtils.loadAnimation(ctx, R.anim.view_zoomin);
											animation.setFillAfter(true);
											animation.setFillEnabled(true);
											animation.setDuration((long) duration);
											
												animation.setAnimationListener(new AnimationListener() {
										     	 
												
												@Override
												public void onAnimationEnd(Animation animation) {
													
	
												}
	
												@Override
												public void onAnimationRepeat(Animation animation) {
													
												}
	
												@Override
												public void onAnimationStart(Animation animation) {
													layouter.setPadding(layouter.getPaddingLeft()-999, 0, 0, 0);
													targetView.setVisibility(View.VISIBLE);
												}
									     	
									     	});

									     	targetView.startAnimation(animation);
									     	
										}
				                	}
									
				                	// WizViewManagerPlugin.callbackShow();
				                	
				                }
				            }
				        );
						result = new PluginResult(Status.OK);
					} else {
						// already shown, just callback
						Log.d("WizViewManagerPlugin", "[show - view already visible]");
						result = new PluginResult(Status.OK);
					}
					
					
				} else {
					// Error handle
					result = new PluginResult(Status.ERROR, "cannot find view");
				}
				
			} catch (JSONException e) {
				// Error handle
				result = new PluginResult(Status.ERROR, "missing view name parameter");
			}
			
	
		} else if (action.equals("updateView")) {
			// Show a particular view...
			Log.d("WizViewManagerPlugin", "[updateView] ****** ");
			
			updateCallbackId = callbackId;
			
			String viewName;
			try {
				viewName = data.getString(0);
				
				// find webview by this name and show it
				if (viewList.has(viewName) ) {
					
					final WebView targetView = (WebView) viewList.get(viewName);
					
					JSONObject options = data.getJSONObject(1);
					
					if (options.has("src")) {
						final String url = options.getString("src");
						
						Log.d("WizViewManagerPlugin", "[updateView] url>> " + url);
						
						Activity mAct = AndroidShellActivity.getActivity();
						mAct.runOnUiThread(
				            new Runnable() {
				                public void run() {
				                	targetView.loadUrl("file://"+url);
//				                	targetView.loadData(url, "text/html", "utf-8");
//				                	targetView.loadData("file://"+url,"text/html", "utf-8" );
				                }
				            }
				        );

					}
					
					result = new PluginResult(Status.NO_RESULT);
					result.setKeepCallback(true);
					

					
				} else {
					// Error handle
					result = new PluginResult(Status.ERROR, "cannot find view");
				}
				
			} catch (JSONException e) {
				// Error handle
				result = new PluginResult(Status.ERROR, "missing view name parameter");
			}
			
	
		}
		
		return result;
	}

	
	
	protected static void callbackShow() {
		
		PluginResult resulter = new PluginResult(com.phonegap.api.PluginResult.Status.OK);
    	resulter.setKeepCallback(false);

    	Plugin wizManagerPlugin = WizViewManagerPlugin.getPluginObj(); 
    	
    	wizManagerPlugin.success(resulter, showCallbackId);
		
	}
	protected static void callbackHide() {
		PluginResult resulter = new PluginResult(com.phonegap.api.PluginResult.Status.OK);
    	resulter.setKeepCallback(false);

    	Plugin wizManagerPlugin = WizViewManagerPlugin.getPluginObj(); 
    	
    	wizManagerPlugin.success(resulter, hideCallbackId);
		
	}

	public static String getUpdatedCallbackId() {
		// return the update callbackId for access outside of plugin
		return updateCallbackId;
	}
	
	public static Plugin getPluginObj() {
		// return the Plugin for access outside of plugin
		return thisPlugin;
	}

	public static JSONObject getViews() {
		// return the viewList for views that request it
		return viewList;
	}

}
