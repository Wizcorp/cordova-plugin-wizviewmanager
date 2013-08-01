/*
 *  __    __ _                  _         _                                                          
 * / / /\ \ (_)______ _ _ __ __| | /\   /(_) _____      __   /\/\   __ _ _ __   __ _  __ _  ___ _ __ 
 * \ \/  \/ / |_  / _` | '__/ _` | \ \ / / |/ _ \ \ /\ / /  /    \ / _` | '_ \ / _` |/ _` |/ _ \ '__|
 *  \  /\  /| |/ / (_| | | | (_| |  \ V /| |  __/\ V  V /  / /\/\ \ (_| | | | | (_| | (_| |  __/ |   
 *   \/  \/ |_/___\__,_|_|  \__,_|   \_/ |_|\___| \_/\_/   \/    \/\__,_|_| |_|\__,_|\__, |\___|_|   
 *                                                                                   |___/                                                                                              |___/                           |___/        
 * @author 	Ally Ogilvie  
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2013
 * @file	- WizViewManagerPlugin.java
 * @about	- Handle view and communication.
*/
package jp.wizcorp.phonegap.plugin.wizViewManager;

import android.view.ViewGroup;
import android.webkit.JsPromptResult;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.api.CordovaInterface;
import org.apache.cordova.api.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;
import android.view.View;
import android.webkit.WebView;

import org.apache.cordova.api.CallbackContext;
import org.apache.cordova.api.CordovaPlugin;

public class WizViewManagerPlugin extends CordovaPlugin {

	private String TAG = "WizViewManagerPlugin";
	static JSONObject viewList = new JSONObject();
    static CordovaInterface _cordova;


	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        _cordova = this.cordova;

        Log.d(TAG, "[action] ****** " + action );

		// By default, get a pointer to mainView and add mainView to the viewList as it always exists (hold phonegap's view)
		if (!viewList.has("mainView")) {
			// Cordova view is not in the viewList so add it.
			try {
				viewList.put("mainView", this.webView);
				Log.d(TAG, "Found CordovaView ****** " + this.webView);
			} catch (JSONException e) {
				// Error handle (this should never happen!)
				callbackContext.error("Critical error. Failed to retrieve Cordova's view");
                Log.e(TAG, "Critical error. Failed to retrieve Cordova's view");
				return true;
			}
		}

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
            final CordovaWebView _cordovaWebView = this.webView;
            // Create link to callback
            final CallbackContext create_cb = callbackContext;

            cordova.getActivity().runOnUiThread(
                    new Runnable() {
                        @Override
                        public void run() {
                            ViewGroup parent = (ViewGroup) _cordovaWebView.getParent().getParent();
                            WizWebView wizWebView = new WizWebView(viewName, settings, parent, cordova.getActivity(), create_cb);

                            // Put our new View into viewList
                            try {
                                viewList.put(viewName, wizWebView);
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

            // Dind webview by this name and remove it
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
				
				// Find webview by this name and hide it
				if (viewList.has(viewName) ) {

                    final WebView targetView = (WebView) viewList.get(viewName);

                    final long duration = animDuration;
                    final String type = animType;

                    cordova.getActivity().runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    if (targetView.getVisibility() == View.VISIBLE) {
                                        /*
                                        hideCallbackId = callbackId;
                                        result = new PluginResult(Status.NO_RESULT);
                                        result.setKeepCallback(true);
                                        */

                                        // get current layout view then add our 999 buffer to bring back to view
                                        // final RelativeLayout layouter = (RelativeLayout) targetView.getParent();

                                        targetView.setVisibility(View.INVISIBLE);
                                        /*
                                        if (targetView.getPaddingLeft() == 0) {

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
                                        }
                                        */

                                    } else {
                                        // already hidden, just callback
                                        Log.d(TAG, "[hide - view already invisible]");

                                        targetView.setVisibility(View.VISIBLE);
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

				// Find webview by this name and show it
				if (viewList.has(viewName) ) {
                    Log.d(TAG, "Get webview in view list");
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
                                        Log.d(TAG, "[show - layouter.getPaddingLeft()] ****** " + targetView.getPaddingLeft());

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
                                        } else {
                                            // already shown, just callback
                                            Log.d(TAG, "[show - view already visible]");
                                            // TEST
                                         targetView.setVisibility(View.VISIBLE);
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

            String viewName = args.getString(0);
            final JSONObject options = args.getJSONObject(1);

            final WizWebView targetView = (WizWebView) viewList.get(viewName);

            cordova.getActivity().runOnUiThread(
                    new Runnable() {
                        @Override
                        public void run() {
                            targetView.setLayout(options);
                        }
                    }
            );

            callbackContext.success();
            return true;

		} else if (action.equals("updateView")) {
            Log.d(TAG, "[updateView] ****** ");
            Log.i(TAG, "Method updateView is DEPRECATED! Use wizViewManager.views.[VIEW_NAME].load(source, successCallback, failureCallback)");
			action = "load";

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

            // Find webview by this name and show it
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
                                    // targetView.loadData(url, "text/html", "utf-8");
                                    // targetView.loadData("file://"+url,"text/html", "utf-8" );
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
        // TODO: return view list
		return null;
	}


    public static void updateViewList() {
        CordovaWebView targetView = null;
        String jsString = "";
        try {
            // Build JS execution String form all view names in viewList
            targetView = (CordovaWebView) viewList.get("mainView");
            JSONArray viewListNameArray = viewList.names();
            jsString += "window.wizViewManager.updateViewList(" + viewListNameArray.toString() + "); ";
            Log.d("wizViewManager", "Execute JS: " + jsString);
            Log.d("wizViewManager", "Updated view list");
        } catch (JSONException ex) {
            return;
        }
        final CordovaWebView _targetView = targetView;
        final String _jsString = jsString;

        _cordova.getActivity().runOnUiThread(
                new Runnable() {
                    public void run() {
                        if (_targetView != null) {
                            _targetView.loadUrl("javascript:" + _jsString);
                        }
                    }
                }
        );

        // Clean up references
        targetView = null;
        jsString = null;
    }
}
