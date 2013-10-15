/* WizViewManager - Handle Popup UIViews and communications.
 *
 * @author Ally Ogilvie
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2013
 * @file WizViewManager.m for PhoneGap
 *
 */ 

#import "WizViewManagerPlugin.h"
#import "WizWebView.h"
#import "WizDebugLog.h"

#import <Cordova/CDVViewController.h>

@implementation WizViewManagerPlugin

@synthesize showViewCallbackId, hideViewCallbackId, webviewDelegate, canvasView;


static NSMutableDictionary *wizViewList = nil;
static CGFloat viewPadder = 9999.0f;
static NSMutableDictionary *viewLoadedCallbackId = nil;
static NSMutableDictionary *isAnimating = nil;
static WizViewManagerPlugin *wizViewManagerInstance = NULL;

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView {

    self = (WizViewManagerPlugin*)[super initWithWebView:theWebView];
    if (self) 
	{
		originalWebViewBounds = theWebView.bounds;
        
        self.webviewDelegate = theWebView.delegate;
        theWebView.delegate = self;
        
        wizViewManagerInstance = self;
    }
    
    // this holds all our views, first we add MainView to our view list by default
    wizViewList = [[NSMutableDictionary alloc ] initWithObjectsAndKeys: theWebView, @"mainView", nil];
    
    // Tell our mainView it IS mainView
    // (We dont need to do this earlier,only for the name mainView
    // to window.name when we are using wizViewManager)
    NSString *js = [NSString stringWithFormat:@"window.name = '%@'", @"mainView"];
    [theWebView stringByEvaluatingJavaScriptFromString:js];   
    
    // this holds callbacks for each view
    viewLoadedCallbackId = [[NSMutableDictionary alloc ] init];
    
    // this holds any views that are animating
    isAnimating = [[NSMutableDictionary alloc ] init];

    // init at nil
    self.showViewCallbackId = nil;
    self.hideViewCallbackId = nil;
    
    [self updateViewList];
    
    return self;
}


+ (NSMutableDictionary *)getViews {
    // return instance of current view list
    return wizViewList;
}

+ (NSMutableDictionary *)getViewLoadedCallbackId {
    // return instance of updateCallbackId
    return viewLoadedCallbackId;
}

+ (WizViewManagerPlugin *)instance {
	return wizViewManagerInstance;
}

- (void)updateViewList {
    
    // Turn view dictionary into an array of view names
    NSArray *viewNames = [[NSArray alloc] initWithArray:[wizViewList allKeys]];
    NSString *viewNamesString = [NSString stringWithFormat:@"'%@'", [viewNames componentsJoinedByString:@"','"]];
    // Inject Javascript to all views
    for (NSString *key in wizViewList) {
        // Found view send message

        // Update wizViewManager.views
        UIWebView *targetWebView = [wizViewList objectForKey:key];
        [targetWebView stringByEvaluatingJavaScriptFromString:
                                   [NSString stringWithFormat:@"window.wizViewManager.updateViewList([%@]);", viewNamesString]];

    }
    [viewNames release];
    
}

- (void)createView:(CDVInvokedUrlCommand *)command {
    
    // Assign arguments
    NSString *viewName      = [command.arguments objectAtIndex:0];
    NSDictionary *options = nil;
    if ([[command.arguments objectAtIndex:1] class] == [NSNull class]) {
        // options are null
        WizLog(@"Null options");
    } else {
        options = [command.arguments objectAtIndex:1];
    }
    
    WizLog(@"[WizViewManagerPlugin] ******* createView name:  %@ withOptions: %@", viewName, options);

    // For a UIWebView we should push the callbackId to stack to use later after source is loaded.
    [viewLoadedCallbackId setObject:command.callbackId forKey:@"updateCallback"];

    // Create a new wizWebView with options (if specified)
    UIWebView *newWizView;

    if (options) {

        NSString *src = [options objectForKey:@"src"];
        if (!src) {
            // default
            src = @"";
        }

        CGRect newRect = [self frameWithOptions:options];

        // Create new wizView
        newWizView = [[WizWebView alloc] createNewInstanceViewFromManager:self newBounds:newRect sourceToLoad:src withOptions:options];

        // Add view name to our wizard view list
        [wizViewList setObject:newWizView forKey:viewName];

        // Move view out of display
        [newWizView setFrame:CGRectMake(
                newWizView.frame.origin.x + viewPadder,
                newWizView.frame.origin.y,
                newWizView.frame.size.width,
                newWizView.frame.size.height
        )];
        [newWizView setHidden:TRUE];

        // Add view to parent UIWebView
        [self.webView.superview addSubview:newWizView];

        // Set a background colour if given one
        if ([options objectForKey:@"backgroundColor"]) {
            NSString *backgroundColor = [options objectForKey:@"backgroundColor"];
            if ([backgroundColor isEqualToString:@"transparent"]) {
                newWizView.backgroundColor = [UIColor clearColor];
            } else {
                newWizView.backgroundColor = [self colorWithHexString:backgroundColor];
            }
        }

    } else {

        // OK default settings apply
        CGRect screenRect = [[UIScreen mainScreen] bounds];

        // Create new wizView
        newWizView = [[WizWebView alloc] createNewInstanceViewFromManager:self newBounds:screenRect sourceToLoad:@"" withOptions:options];

        // Add view name to our wizard view list
        [wizViewList setObject:newWizView forKey:viewName];


        // Move view out of display
        [newWizView setFrame:CGRectMake(
                newWizView.frame.origin.x + viewPadder,
                newWizView.frame.origin.y,
                newWizView.frame.size.width,
                newWizView.frame.size.height
        )];

        // Add view to parent WebView
        [self.webView.superview addSubview:newWizView];
    }

    [self updateViewList];

    WizLog(@"[WizViewManagerPlugin] ******* current views... %@", wizViewList);
}

- (void)hideView:(CDVInvokedUrlCommand *)command {
    
    NSString *viewName = [command.arguments objectAtIndex:0];

    if ([wizViewList objectForKey:viewName]) {
        // Hide the web view
        [self hideWebView:command];
    } else {
        // View not found
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"view not found!"];
        [self writeJavascript: [pluginResult toErrorCallbackString:command.callbackId]];
        return;
    }
}

- (void)hideWebView:(CDVInvokedUrlCommand *)command {
        
    // Assign arguments
    WizLog(@"Start hideView with callback :  %@", command.callbackId);
    NSString *viewName = [command.arguments objectAtIndex:0];
    NSDictionary *options = nil;
    if ([[command.arguments objectAtIndex:1] class] == [NSNull class]) {
        // options are null
        WizLog(@"Null options");
    } else {
        options = [command.arguments objectAtIndex:1];
    }

    CDVPluginResult *pluginResultOK = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    if ([wizViewList objectForKey:viewName]) {
        UIWebView *targetWebView = [wizViewList objectForKey:viewName];

        WizLog(@"[WizViewManager] ******* hideView animating Views : %@ is hidden? %i", isAnimating, !targetWebView.isHidden);

        if (!targetWebView.isHidden || [isAnimating objectForKey:viewName]) {
                       
            if ([isAnimating objectForKey:viewName]) {
                // View is animating - stop current animation can release previous callback
                // [isAnimating removeObjectForKey:viewName];

                WizLog(@"[WizViewManager] ******* hideView hideViewCallbackId %@", self.hideViewCallbackId);
                WizLog(@"[WizViewManager] ******* hideView showViewCallbackId %@", self.showViewCallbackId);
                if (self.hideViewCallbackId.length > 0) {
                    NSLog(@"[WizViewManager] ******* hideView, callback to hide - %@", self.hideViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.hideViewCallbackId]];
                    self.hideViewCallbackId = nil;
                    // We are hiding when hiding, exit.
                    WizLog(@"returning - already hiding animation");
                    return;
                }
                if (self.showViewCallbackId.length > 0) {
                    WizLog(@"[WizViewManager] ******* showView, callback to show - %@", self.showViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.showViewCallbackId]];
                    self.showViewCallbackId = nil;
                }
            }
            
            // About to animate (even if we are not) so add to animate store
            // [isAnimating setObject:targetWebView forKey:viewName];
            
            self.hideViewCallbackId = command.callbackId;

            if (options) {
                NSDictionary *animationDict = [options objectForKey:@"animation"];
                
                if (animationDict) {
                    
                    NSString *type               = [animationDict objectForKey:@"type"];
                    int animateTimeinMilliSecs   = [[animationDict objectForKey:@"duration"] intValue];
                    CGFloat animateTime          = (CGFloat)animateTimeinMilliSecs / 1000;
                    if (!animateTime) {
                        // Default
                        animateTime = 0.3f;
                    }
                    // WizLog(@"[WizViewManager] ******* hideView animateTime : %f ", animateTime);
                    if (!type) {
                        
                        // Default
                        [self hideWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState viewName:viewName];
                        
                    } else if ([type isEqualToString:@"zoomOut"]) {
                        
                        [self hideWithZoomOutAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState viewName:viewName];
                        
                    } else if ([type isEqualToString:@"fadeOut"]) {
                        
                        [self hideWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToLeft"]) {
                        
                        [self hideWithSlideOutToLeftAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToRight"]) {
                        
                        [self hideWithSlideOutToRightAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToTop"]) {
                        
                        [self hideWithSlideOutToTopAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToBottom"]) {
                        
                        [self hideWithSlideOutToBottomAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState viewName:viewName];
                        
                    } else {
                        // Not found do "none"
                        [self hideWithNoAnimation:targetWebView];
                        // Not animating so remove from animate store
                        [isAnimating removeObjectForKey:viewName];
                    }
                    
                } else {
                    // Not found do "none"
                    [self hideWithNoAnimation:targetWebView];
                    // Not animating so remove from animate store
                    [isAnimating removeObjectForKey:viewName];
                }
                
            } else {
                // Not found do "none"
                [self hideWithNoAnimation:targetWebView];
                // Not animating so remove from animate store
                [isAnimating removeObjectForKey:viewName];
            }
            
        } else {
            // Target already hidden do nothing
            WizLog(@"[WizViewManager] ******* target already hidden! ");
            [self writeJavascript: [pluginResultOK toSuccessCallbackString:command.callbackId]];
        }

        // Other callbacks come from after view is added to animation object

    } else {
        
        CDVPluginResult *pluginResultErr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResultErr toErrorCallbackString:command.callbackId]];
        
    }
}

- (void)showView:(CDVInvokedUrlCommand *)command {
    
    NSString *viewName = [command.arguments objectAtIndex:0];

    if ([wizViewList objectForKey:viewName]) {
        // Show the web view
        [self showWebView:command];
    } else {
        // View not found
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"view not found!"];
        [self writeJavascript: [pluginResult toErrorCallbackString:command.callbackId]];
        return;
    }
}

- (void)showWebView:(CDVInvokedUrlCommand *)command {
    // Show a web view type
    // Assign arguments
    WizLog(@"Start showWebView with callback :  %@", command.callbackId);
    NSString *viewName = [command.arguments objectAtIndex:0];
    NSDictionary *options = nil;
    if ([[command.arguments objectAtIndex:1] class] == [NSNull class]) {
        // options are null
        WizLog(@"Null options");
    } else {
        options = [command.arguments objectAtIndex:1];
    }

    CDVPluginResult *pluginResultOK = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    CDVPluginResult *pluginResultERROR = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

    if ([wizViewList objectForKey:viewName]) {
        UIWebView *targetWebView = [wizViewList objectForKey:viewName];

        WizLog(@"[WizViewManager] ******* showView animating object : %@ is hidden? %i", isAnimating, targetWebView.isHidden);

        if (targetWebView.isHidden || [isAnimating objectForKey:viewName]) {
            
            if ([isAnimating objectForKey:viewName]) {
                // view is animating - stop current animation can release previous callback
                
                //[isAnimating removeObjectForKey:viewName];

                WizLog(@"[WizViewManager] ******* showView hideViewCallbackId %@", self.hideViewCallbackId);
                WizLog(@"[WizViewManager] ******* showView showViewCallbackId %@", self.showViewCallbackId);
                if (self.hideViewCallbackId.length > 0) {
                    WizLog(@"[WizViewManager] ******* showView, callback to hide - %@", self.hideViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.hideViewCallbackId]];
                    self.hideViewCallbackId = nil;
                }
                if (self.showViewCallbackId.length > 0) {
                    WizLog(@"[WizViewManager] ******* showView, callback to show - %@", self.showViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.showViewCallbackId]];
                    self.showViewCallbackId = nil;
                    // we are showing when showing, exit.
                    WizLog(@"returning - already showing animation");
                    return;
                }
            }

            self.showViewCallbackId = command.callbackId;

            if (options) {
                
                NSDictionary *animationDict = [options objectForKey:@"animation"];
                
                if (animationDict) {

                    WizLog(@"[WizViewManager] ******* with options : %@ ", options);
                    NSString *type               = [animationDict objectForKey:@"type"];
                    int animateTimeinMilliSecs   = [[animationDict objectForKey:@"duration"] intValue];
                    CGFloat animateTime          = (CGFloat)animateTimeinMilliSecs / 1000;
                    if (!animateTime) {
                        // Default
                        animateTime = 0.3f;
                    }
                    // NSLog(@"[WizViewManager] ******* showView animateTime : %f ", animateTime);
                    
                    if (!type) {
                        
                        // Default
                        [self showWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:command.callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"zoomIn"]) {
                        
                        [self showWithZoomInAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:command.callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"fadeIn"]) {
                        
                        [self showWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:command.callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromLeft"]) {
                        
                        [self showWithSlideInFromLeftAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:command.callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromRight"]) {
                        
                        [self showWithSlideInFromRightAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:command.callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromTop"]) {
                        
                        [self showWithSlideInFromTopAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:command.callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromBottom"]) {
                        
                        [self showWithSlideInFromBottomAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:command.callbackId viewName:viewName];
                        
                    } else {
                        // Not found do "none"
                        [self showWithNoAnimation:targetWebView];
                        // Not animating so remove from animate store
                        [isAnimating removeObjectForKey:viewName];
                        [self writeJavascript: [pluginResultOK toSuccessCallbackString:command.callbackId]];
                        self.showViewCallbackId = nil;
                    }
                    
                } else {
                    // Not found do "none"
                    [self showWithNoAnimation:targetWebView];
                    // Not animating so remove from animate store
                    [isAnimating removeObjectForKey:viewName];
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:command.callbackId]];
                    self.showViewCallbackId = nil;
                }

            } else {
                // Not found do "none"
                [self showWithNoAnimation:targetWebView];
                // Not animating so remove from animate store
                [isAnimating removeObjectForKey:viewName];
                [self writeJavascript: [pluginResultOK toSuccessCallbackString:command.callbackId]];
                self.showViewCallbackId = nil;
            }
                
        } else {
            // Target already showing
            WizLog(@"[WizViewManager] ******* target already shown! ");
            [self writeJavascript: [pluginResultERROR toErrorCallbackString:command.callbackId]];
            self.showViewCallbackId = nil;
        }

    } else {
                
        CDVPluginResult* pluginResultErr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResultErr toErrorCallbackString:command.callbackId]];
    }
}

- (void)load:(CDVInvokedUrlCommand *)command {
    // assign arguments
    NSString *viewName    = [command.arguments objectAtIndex:0];
    NSDictionary* options = [command.arguments objectAtIndex:1];

    WizLog(@"[WizViewManager] ******* Load into view : %@ - viewlist -> %@ options %@", viewName, wizViewList, options);

    if (options) {
        
        // Search for view
        if ([wizViewList objectForKey:viewName]) {
            
            NSString *src = [options objectForKey:@"src"];
            
            if ([src length] > 0) {
                WizLog(@"[WizViewManager] ******* loading source to view : %@ ", viewName);
            } else {
                WizLog(@"Load Error: no source");
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Load Error: no sourc"];
                [self writeJavascript: [pluginResult toErrorCallbackString:command.callbackId]];
                return;
            }

            // UIWebView requires we keep the callback to be accessed by the UIWebView itself
            // to return later once finished parsing script
            [viewLoadedCallbackId setObject:command.callbackId forKey:@"viewLoadedCallback"];

            UIWebView *targetWebView = [wizViewList objectForKey:viewName];

            if ([self validateUrl:src]) {
                // load new source
                // source is url
                // NSLog(@"SOURCE IS URL %@", src);
                NSURL *newURL = [NSURL URLWithString:src];

                // JC- Setting the service type to video somehow seems to
                // disable the reuse of this connection for pipelining new
                // HTTP requests, which apparently fixes the tying of these
                // requests to the ajax connection used for the message streams
                // (which is initiated from the Javascript realm).
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:newURL];
                [request setNetworkServiceType:NSURLNetworkServiceTypeVideo];

                [targetWebView loadRequest:request];

            } else {
                // NSLog(@"SOURCE NOT URL %@", src);
                NSString *fileString = src;

                NSString *newHTMLString = [[NSString alloc] initWithContentsOfFile: fileString encoding: NSUTF8StringEncoding error: NULL];

                NSURL *newURL = [[NSURL alloc] initFileURLWithPath: fileString];

                [targetWebView loadHTMLString: newHTMLString baseURL: newURL];

                [newHTMLString release];
                [newURL release];
            }

        } else {
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
            [self writeJavascript: [pluginResult toErrorCallbackString:command.callbackId]];
            
        }
        
    } else {
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - no options passed"];
        [self writeJavascript: [pluginResult toErrorCallbackString:command.callbackId]];
        
    }
    
    // For UIWebViews; all view list arrays are updated once the source has been loaded.
}

- (void)removeView:(CDVInvokedUrlCommand *)command {
    // Assign arguments
    NSString *viewName    = [command.arguments objectAtIndex:0];
    WizLog(@"[WizViewManager] ******* removeView name : %@ ", viewName);
    
    // Search for view
    if ([wizViewList objectForKey:viewName]) {

        // Get the view from the view list
        UIWebView *targetWebView = [wizViewList objectForKey:viewName];

        // Remove the view!
        [targetWebView removeFromSuperview];
        [targetWebView release];
        targetWebView.delegate = nil;
        targetWebView = nil;

        // Remove the view from wizViewList
        [wizViewList removeObjectForKey:viewName];
        
        [self updateViewList];
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:command.callbackId]];

        WizLog(@"[WizViewManager] ******* removeView views left : %@ ", wizViewList);

    } else {
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResult toErrorCallbackString:command.callbackId]];
    }
    
}


- (CGRect)frameWithOptions:(NSDictionary *)options {

    // Get Device width and height
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int screenHeight = (int) screenRect.size.height;
    int screenWidth = (int) screenRect.size.width;
    
    // Define vars
    int top;
    int left;
    int width;
    int height;
    
    if (options) {
        // NSLog(@"SIZING OPTIONS: %@", options);
        
        if ([options objectForKey:@"top"]) {
            top = [self getWeakLinker:[options objectForKey:@"top"] ofType:@"top"];
        } else if ([options objectForKey:@"y"]) {
            // backward compatibility
            top = [self getWeakLinker:[options objectForKey:@"y"] ofType:@"top"];
        } else if ([options objectForKey:@"height"] && [options objectForKey:@"bottom"]) {
            top = screenHeight - [self getWeakLinker:[options objectForKey:@"bottom"] ofType:@"bottom"]
            - [self getWeakLinker:[options objectForKey:@"height"] ofType:@"height"];
        } else {
            top = 0;
        }
        // NSLog(@"TOP: %i", top);
        
        if ([options objectForKey:@"left"]) {
            left = [self getWeakLinker:[options objectForKey:@"left"] ofType:@"left"];
        } else if ([options objectForKey:@"x"]) {
            // backward compatibility
            left = [self getWeakLinker:[options objectForKey:@"x"] ofType:@"left"];
        } else if ([options objectForKey:@"width"] && [options objectForKey:@"right"]) {
            left = screenWidth - [self getWeakLinker:[options objectForKey:@"right"] ofType:@"right"]
            - [self getWeakLinker:[options objectForKey:@"width"] ofType:@"width"];
        } else {
            left = 0;
        }
        // NSLog(@"LEFT: %i", left);
        
        if ([options objectForKey:@"height"]) {
            height = [self getWeakLinker:[options objectForKey:@"height"] ofType:@"height"];
        } else if ([options objectForKey:@"bottom"]) {
            height = screenHeight - [self getWeakLinker:[options objectForKey:@"bottom"] ofType:@"bottom"] - top;
        } else {
            height = screenHeight;
        }
        // NSLog(@"HEIGHT: %i", height);
        
        if ([options objectForKey:@"width"]) {
            width = [self getWeakLinker:[options objectForKey:@"width"] ofType:@"width"];
        } else if ([options objectForKey:@"right"]) {
            width = screenWidth - [self getWeakLinker:[options objectForKey:@"right"] ofType:@"right"] - left;
        } else {
            width = screenWidth;
        }
        // NSLog(@"WIDTH: %i", width);
    } else {
        // Defaults to full screen fill
        top = 0;
        left = 0;
        height = screenHeight;
        width = screenWidth;
        // NSLog(@"TOP: 0\nLEFT: 0\nHEIGHT: %i\nWIDTH: %i", height, width);
    }
    
    // NSLog(@"MY PARAMS left: %i, top: %i, width: %i, height: %i", left, top, width,height);
    
    return CGRectMake(left, top, width, height);
}

- (void)setLayout:(CDVInvokedUrlCommand *)command {
    // Assign arguments
    NSString *viewName    = [command.arguments objectAtIndex:0];
    NSDictionary *options = [command.arguments objectAtIndex:1];
    
    // NSLog(@"[WizViewManagerPlugin] ******* resizeView name:  %@ withOptions: %@", viewName, options);
    
    if ([wizViewList objectForKey:viewName]) {

        // SetLayout UIWebView
        UIWebView* targetWebView = [wizViewList objectForKey:viewName];

        CGRect newRect = [self frameWithOptions:options];
        if (targetWebView.isHidden) {
            // if hidden add padding
            newRect.origin = CGPointMake(newRect.origin.x + viewPadder, newRect.origin.y);
        }
        targetWebView.frame = newRect;

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:command.callbackId]];
        
    } else {
        // NSLog(@"view not found!");
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"view not found!"];
        [self writeJavascript: [pluginResult toErrorCallbackString:command.callbackId]];
    }
}

- (void)sendMessage:(NSString *)viewName withMessage:(NSString *)message {
    // Send a message to a view
       
    if ([wizViewList objectForKey:viewName]) {
        // Found view send message

        // Escape the message
        NSString *postDataEscaped = [message stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];

        // Message UIWebView
        UIWebView* targetWebView = [wizViewList objectForKey:viewName];
        [targetWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"wizMessageReceiver(window.decodeURIComponent('%@'));", postDataEscaped]];

    } else {
        WizLog(@"Message failed! View not found!");
    }
}

- (int)getWeakLinker:(NSString*)myString ofType:(NSString*)type {
    // Do tests to get correct int (we read in as string pointer but infact we are unaware of the var type)
    int i;
    
    if (!myString || !type) {
        // got null value in method params
        return i = 0;
    }
    
    // NSLog(@"try link : %@ for type: %@", myString, type);

    // Get Device width and height
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;

    // Test for percentage
    NSArray *percentTest = [self percentTest:myString];
    
    if (percentTest) {
        // It was a percent do calculation and assign value
        
        int j = [[percentTest objectAtIndex:0] intValue];
        
        if ([type isEqualToString:@"width"] || [type isEqualToString:@"left"] || [type isEqualToString:@"right"]) {
            float k = j*0.01; // use float here or int is rounded to a 0 int
            i = k*screenWidth;
        } else if ([type isEqualToString:@"height"] || [type isEqualToString:@"top"] || [type isEqualToString:@"bottom"]) {
            float k = j*0.01; // use float here or int is rounded to a 0 int
            i = k*screenHeight;
        } else {
            //invalid type - not supported
            i = 0;
        }
        
    } else {
        
        // test - float
        BOOL floatTest= [self floatTest:myString];
        if (floatTest) {
            // We have a float, check our float range and convert to int
            float floatValue = [myString floatValue];
            if (floatValue < 1.0) {
                if ([type isEqualToString:@"width"] || [type isEqualToString:@"left"] || [type isEqualToString:@"right"]) {
                    i = (floatValue * screenWidth);
                } else if ([type isEqualToString:@"height"] || [type isEqualToString:@"top"] || [type isEqualToString:@"bottom"]) {
                    i = (floatValue * screenHeight);
                } else {
                    // Invalid type - not supported
                    i = 0;
                }
            } else {
                // Not good float value - defaults to 0
                i = 0;
            }
            
        } else {
            
            // Third string test - assume an int?
            i = [myString intValue];
        }
        
    }
    
    // NSLog(@"weak linked : %i for type: %@", i, type);
    return i;
    
}

- (BOOL)validateUrl:(NSString *)candidate {
    NSString *lowerCased = [candidate lowercaseString];
    return [lowerCased hasPrefix:@"http://"] || [lowerCased hasPrefix:@"https://"];
}

- (BOOL)floatTest:(NSString *)myString {
    NSString *realString = [[NSString alloc] initWithString:myString];
    NSArray *floatTest = [realString componentsSeparatedByString:@"."];
    [realString release];
    if (floatTest.count > 1) {
        // found decimal. must be a float
        return TRUE;
    } else {
        // failed test
        return FALSE;
    }
}

- (NSArray *)percentTest:(NSString *)myString {
    NSString *realString = [[NSString alloc] initWithString:myString];
    NSArray *percentTest = [realString componentsSeparatedByString:@"%"];
    [realString release];
    
    if (percentTest.count > 1) {
        // found percent mark. must be a percent
        return percentTest;
    } else {
        // failed test
        return NULL;
    }
}

/**
 
 COLOUR CALCULATOR
 
 **/
- (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];          
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];                      
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];                      
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RGB, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

/**
 
 ANIMATION METHODS
 
 **/
- (void)showViewCallbackMethod:(NSString *)callbackId viewName:(NSString *)viewName {
    
    if (self.showViewCallbackId.length > 0) {
        // We are still animating without interruption so continue callback
        NSString *callback = self.showViewCallbackId;
        self.showViewCallbackId = nil;
        NSLog(@"[SHOW] callback to %@", callback);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:callback]];
    }

}

- (void)showWithNoAnimation:(UIView *)view {
    // Move view into display
    [view setFrame:CGRectMake(
                              view.frame.origin.x - viewPadder,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    view.alpha = 1.0;
}

- (void)hideWithNoAnimation:(UIView *)view {
    view.alpha = 0.0;
    [view setHidden:TRUE];
    // move view out of display
    [view setFrame:CGRectMake(
                              view.frame.origin.x + viewPadder,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    self.hideViewCallbackId = nil;
}

- (void)showWithSlideInFromTopAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName {
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    // Move view to bottom of visible display
    [view setFrame:CGRectMake(
                              view.frame.origin.x - viewPadder,
                              view.frame.origin.y - screenHeight,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    view.alpha = 1.0;
    // Now return the view to normal dimension, animating this transformation
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, 0, screenHeight);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
}

- (void)hideWithSlideOutToTopAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName {
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, 0, -screenHeight);
                     }
                     completion:^(BOOL finished) { 
                         if (finished) {
                             [view setHidden:TRUE];
                             
                             // move view out of display
                             [view setFrame:CGRectMake(
                                                       view.frame.origin.x + viewPadder,
                                                       (view.frame.origin.y + screenHeight),
                                                       view.frame.size.width,
                                                       view.frame.size.height
                                                       )];
                             
                             // no animate so remove from animate store
                             [isAnimating removeObjectForKey:viewName];
                             self.hideViewCallbackId = nil;
                         }
                     }];
}

- (void)showWithSlideInFromBottomAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName {
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    // move view to bottom of visible display      
    [view setFrame:CGRectMake(
                              view.frame.origin.x - viewPadder,
                              view.frame.origin.y + screenHeight,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    view.alpha = 1.0;
    // now return the view to normal dimension, animating this tranformation
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, 0, -screenHeight);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
}

- (void)hideWithSlideOutToBottomAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName {
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, 0, screenHeight);
                     }
                     completion:^(BOOL finished) { 
                         if (finished) {
                             [view setHidden:TRUE];
                             
                             // move view out of display
                             [view setFrame:CGRectMake(
                                                       view.frame.origin.x + viewPadder,
                                                       (view.frame.origin.y - screenHeight),
                                                       view.frame.size.width,
                                                       view.frame.size.height
                                                       )];
                             
                             // no animate so remove from animate store
                             [isAnimating removeObjectForKey:viewName];
                             self.hideViewCallbackId = nil;
                         }
                     }];
}

- (void)showWithSlideInFromRightAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName {
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    // Move view to right of visible display
    [view setFrame:CGRectMake(
                              (view.frame.origin.x - viewPadder) + screenWidth,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    view.alpha = 1.0;
    // Now return the view to normal dimension, animating this tranformation
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, -screenWidth, 0);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
}

- (void)hideWithSlideOutToRightAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName {
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, screenWidth, 0);
                     }
                     completion:^(BOOL finished) { 
                         if (finished) {
                             [view setHidden:TRUE];
                             
                             // move view out of display
                             [view setFrame:CGRectMake(
                                                       (view.frame.origin.x - screenWidth) + viewPadder,
                                                       view.frame.origin.y,
                                                       view.frame.size.width,
                                                       view.frame.size.height
                                                       )];
                             
                             // no animate so remove from animate store
                             [isAnimating removeObjectForKey:viewName];
                             self.hideViewCallbackId = nil;
                         }
                     }];
}


- (void)showWithSlideInFromLeftAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName {

    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    // Move view to left of visible display
    [view setFrame:CGRectMake(
                              (view.frame.origin.x - viewPadder) - screenWidth,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    [view setAlpha:1.0];
    // Now return the view to normal dimension, animating this tranformation
    
   
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, screenWidth, 0);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
     
}

- (void)hideWithSlideOutToLeftAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName {
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, -screenWidth, 0);
                     }
                     completion:^(BOOL finished) { 
                         if (finished) {
                             [view setHidden:TRUE];
                             
                             // move view out of display
                             [view setFrame:CGRectMake(
                                                       (view.frame.origin.x + screenWidth) + viewPadder,
                                                       view.frame.origin.y,
                                                       view.frame.size.width,
                                                       view.frame.size.height
                                                       )];
                             
                             // no animate so remove from animate store
                             [isAnimating removeObjectForKey:viewName];
                             self.hideViewCallbackId = nil;
                         }
                     }];
                
}

- (void)showWithZoomInAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString *)viewName {

    // First reduce the view to 1/100th of its original dimension
    CGAffineTransform trans = CGAffineTransformScale(view.transform, 0.01, 0.01);
    view.transform = trans;	// do it instantly, no animation
    // Move view into display
    [view setFrame:CGRectMake(
               view.frame.origin.x - viewPadder,
               view.frame.origin.y,
               view.frame.size.width,
               view.frame.size.height
               )];
    [view setHidden:FALSE];
    // [self addSubview:view];
    // Now return the view to normal dimension, animating this tranformation
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformScale(view.transform, 100.0, 100.0);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];	
}





- (void)hideWithZoomOutAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName {
    
	[UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformScale(view.transform, 0.01, 0.01);
                     }
                     completion:^(BOOL finished) { 
                         if (finished) {
                             // [self removeFromSuperview]; 
                             [view setHidden:TRUE];
                             // move view out of display
                             [view setFrame:CGRectMake(
                                        view.frame.origin.x + viewPadder,
                                        view.frame.origin.y,
                                        view.frame.size.width,
                                        view.frame.size.height
                                        )];
                             
                             // no animate so remove from animate store
                             [isAnimating removeObjectForKey:viewName];
                             self.hideViewCallbackId = nil;
                         }
                     }];
}


- (void)showWithFadeAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString *)viewName {
    
    WizLog(@"SHOW FADE view is %@, %@", view, viewName);
    // Check frame x co ordinate is the same (in case of mid animation), if different we need to reset frame

    if (![isAnimating objectForKey:viewName]) {
        WizLog(@"move view ");
        view.alpha = 0.0;
        // move view into display       
        [view setFrame:CGRectMake(
                                  view.frame.origin.x - viewPadder,
                                  view.frame.origin.y,
                                  view.frame.size.width,
                                  view.frame.size.height
                                  )];
    }
    
    // About to animate so add to animate store
    [isAnimating setObject:view forKey:viewName];

    [view setHidden:FALSE];
    WizLog(@"START show animate");
	[UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                        if (finished) {
                            WizLog(@"FINISHED show animate %i", finished);
                            // finished animation remove from animate store
                            [isAnimating removeObjectForKey:viewName];
                            [self showViewCallbackMethod:callbackId viewName:viewName];
                        }
                         
                     }];
    
    

}
// [self performSelector:@selector(_userLoggedIn) withObject:nil afterDelay:0.010f];

- (void)hideWithFadeAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName {
    WizLog(@"HIDE FADE view is %@, %@", view, viewName);
    // about to animate so add to animate store
    
    if (![isAnimating objectForKey:viewName]) {
        view.alpha = 1.0;	// make the view transparent
    }
    
    [isAnimating setObject:view forKey:viewName];
    
    CDVPluginResult* pluginResultOK = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.hideViewCallbackId]];
    
    //[self addSubview:view];	// add it
	[UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{view.alpha = 0.0;}
                     completion:^(BOOL finished) { 
                         if (finished) {
                             WizLog(@"finished HIDE animate %i", finished);

                             [view setHidden:TRUE];
                             // move view out of display
                             [view setFrame:CGRectMake(
                                                       view.frame.origin.x + viewPadder,
                                                       view.frame.origin.y,
                                                       view.frame.size.width,
                                                       view.frame.size.height
                                                       )];
                             // no animate so remove from animate store
                             [isAnimating removeObjectForKey:viewName];
                             self.hideViewCallbackId = nil;
                         }
                         
                     }];	// animate the return to visible 
}

/*
 * Extend CordovaView URL request handler
 *
 */
- (void)webViewDidStartLoad:(UIWebView *)theWebView {
    return [self.webviewDelegate webViewDidStartLoad:theWebView];
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    return [self.webviewDelegate webViewDidFinishLoad:theWebView];
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error {
    return [self.webviewDelegate webView:theWebView didFailLoadWithError:error];
}

-(BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    BOOL superValue = [ self.webviewDelegate webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType ];

    // If get this request reboot...
    NSString *requestString = [[request URL] absoluteString];
    NSArray *prefixer = [requestString componentsSeparatedByString:@":"];
        
    // Do insensitive compare to support SDK >5
    if ([(NSString *)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"rebootapp"] == 0) {
        
        // Perform restart a second later
        [self performSelector:@selector(timedRestart) withObject:theWebView afterDelay:1.0f];
        
        return NO;
		
	} else if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"wizPostMessage"] == 0) {
        
        NSArray *requestComponents = [requestString componentsSeparatedByString:@"://"];
        NSString *postMessage = [[NSString alloc] initWithString:(NSString*)[requestComponents objectAtIndex:1]];
        
        NSArray *messageComponents = [postMessage componentsSeparatedByString:@"?"];
        
        NSString *originView = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:0]];
        NSString *targetView = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:1]];
        NSString *data = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:2]];
        NSString *type = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:3]];
        
        NSLog(@"[WizWebView] ******* targetView is:  %@", targetView );
               
        // NSLog(@"[AppDelegate wizMessageView()] ******* postData is:  %@", postData );
        
        NSMutableDictionary *viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];

        NSString *postDataEscaped = [data stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];

        UIWebView* targetWebView = [viewList objectForKey:targetView];
        NSString *js = [NSString stringWithFormat:@"wizViewMessenger.__triggerMessageEvent( window.decodeURIComponent('%@'), window.decodeURIComponent('%@'), window.decodeURIComponent('%@'), '%@' );", originView, targetView, postDataEscaped, type];
        [targetWebView stringByEvaluatingJavaScriptFromString:js];

            // WizLog(@"[AppDelegate wizMessageView()] ******* current views... %@", viewList);

        [postMessage release];
        postMessage = nil;
        [originView release];
        [targetView release];
        [data release];
        [viewList release];

        return NO;
        
 	} else {
        // let Cordova handle everything else
        return superValue;
    }

}

-(void)timedRestart:(UIWebView *)theWebView {
    // Gives time for our JS method to execute splash

    // Remove all views
    NSArray *allKeys = [NSArray arrayWithArray:[wizViewList allKeys]];
    
    for (int i = 0; i<[allKeys count]; i++) {
        
        if (![[allKeys objectAtIndex:i] isEqualToString:@"mainView"]) {
            CDVInvokedUrlCommand *cmd = [[CDVInvokedUrlCommand alloc] initWithArguments:[NSArray arrayWithObjects:[allKeys objectAtIndex:i], nil] callbackId:@"" className:@"WizViewManagerPlugin" methodName:@"removeView"];
            [self removeView:cmd];
            [cmd release];
        }
        
    }
    
    // Resize mainView to normal
    CDVInvokedUrlCommand *cmd = [[CDVInvokedUrlCommand alloc] initWithArguments:[NSArray arrayWithObjects:@"mainView", nil] callbackId:@"" className:@"WizViewManagerPlugin" methodName:@"setLayout"];
    [self setLayout:cmd];
    [cmd release];
    
    [theWebView reload];
}

@end