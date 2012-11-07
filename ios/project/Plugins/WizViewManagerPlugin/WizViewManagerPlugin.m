/* WizViewManager - Handle Popup UIViews and communications.
 *
 * @author Ally Ogilvie
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file WizViewManager.m for PhoneGap
 *
 */ 

#import "WizViewManagerPlugin.h"
#import "WizWebView.h"
#import "WizDebugLog.h"
#import <QuartzCore/QuartzCore.h>


@implementation WizViewManagerPlugin

@synthesize showViewCallbackId, hideViewCallbackId, webviewDelegate;


static NSMutableDictionary *wizViewList = nil;
static CGFloat viewPadder = 9999.0f;
static NSMutableDictionary *viewLoadedCallbackId = nil;
static NSMutableDictionary *isAnimating = nil;

-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{

    self = (WizViewManagerPlugin*)[super initWithWebView:theWebView];
    if (self) 
	{
		originalWebViewBounds = theWebView.bounds;
        
        self.webviewDelegate = theWebView.delegate;
        theWebView.delegate = self;
        
    }
    
    // this holds all our views, first we add MainView to our view list by default
    wizViewList = [[NSMutableDictionary alloc ] initWithObjectsAndKeys: theWebView, @"mainView", nil];
    
    // this holds callbacks for each view
    viewLoadedCallbackId = [[NSMutableDictionary alloc ] init];
    
    // this holds any views that are animating
    isAnimating = [[NSMutableDictionary alloc ] init];

    // init at nil
    self.showViewCallbackId = nil;
    self.hideViewCallbackId = nil;
    
    return self;
}


+ (NSMutableDictionary*)getViews
{
    // return instance of current view list
    return wizViewList;
}

+ (NSMutableDictionary*)getViewLoadedCallbackId
{
    // return instance of updateCallbackId
    return viewLoadedCallbackId;
}


- (void)load:(NSArray*)arguments withDict:(NSDictionary*)options
{
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName    = [arguments objectAtIndex:1];
    
    [viewLoadedCallbackId setObject:callbackId forKey:@"viewLoadedCallback"];
    
    // NSLog(@"[WizViewManager] ******* Load into view : %@ - viewlist -> %@ options %@", viewName, wizViewList, options); 
    
    
    if (options) 
	{
        
        // search for view
        if ([wizViewList objectForKey:viewName]) {
            UIWebView *targetWebView = [wizViewList objectForKey:viewName]; 
            
            NSString *src               = [options objectForKey:@"src"];
            if (src) {
                
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
                
            }
            
        } else {
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
            [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
            
        }
        
    } else {
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - no options passed"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
        
    }
}

- (void)updateView:(NSArray*)arguments withDict:(NSDictionary*)options 
{
    /*
     *
     *
     * DEPRECIATED - use (void)loadInView:(NSArray*)arguments withDict:(NSDictionary*)options
     *
     * or JavaScript wizViewManager.load(String viewName, String URL or URI, success, fail)
     *
     *
     *
     */
    
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName    = [arguments objectAtIndex:1];
    
    [viewLoadedCallbackId setObject:callbackId forKey:@"viewLoadedCallback"];
    
    // NSLog(@"[WizViewManager] ******* updateView name : %@ ", viewName); 

    
    // wait for callback
    
    if (options) 
	{
            
        // search for view
        if ([wizViewList objectForKey:viewName]) {
            UIWebView* targetWebView = [wizViewList objectForKey:viewName]; 
            
            NSString* src               = [options objectForKey:@"src"];
            if (src) {
                
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
                
            }
            
            
        } else {
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
            [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
        
        }
 
    } else {
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - no options passed"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
        
    }
      
}   


- (void)removeView:(NSArray*)arguments withDict:(NSDictionary*)options
{
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName    = [arguments objectAtIndex:1];
    
    NSLog(@"[WizViewManager] ******* removeView name : %@ ", viewName);
    
    // search for view
    if ([wizViewList objectForKey:viewName]) {
        UIWebView *targetWebView = [wizViewList objectForKey:viewName]; 
        
        // remove the view from wizViewList
        [wizViewList removeObjectForKey:viewName];
        
        // remove the view!
        [targetWebView removeFromSuperview];
        [targetWebView release];
        targetWebView.delegate = nil;
        targetWebView = nil;
        

        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];
        
        
         NSLog(@"[WizViewManager] ******* removeView views left : %@ ", wizViewList);
    } else {
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
    }
    
}


- (CGRect) frameWithOptions:(NSDictionary*)options
{
    // get Device width and height
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int screenHeight = (int) screenRect.size.height;
    int screenWidth = (int) screenRect.size.width;
    
    // define vars
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
        top = 0;
        left = 0;
        height = screenHeight;
        width = screenWidth;
        // NSLog(@"TOP: 0\nLEFT: 0\nHEIGHT: %i\nWIDTH: %i", height, width);
    }
    
    // NSLog(@"MY PARAMS left: %i, top: %i, width: %i, height: %i", left, top, width,height);
    
    return CGRectMake(left, top, width, height);
}

- (void)setLayout:(NSArray*)arguments withDict:(NSDictionary*)options
{
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName    = [arguments objectAtIndex:1];
    
    // NSLog(@"[WizViewManagerPlugin] ******* resizeView name:  %@ withOptions: %@", viewName, options);
    
    if ([wizViewList objectForKey:viewName]) {
        UIWebView* targetWebView = [wizViewList objectForKey:viewName];
        // NSLog(@"got view! %@", targetWebView);
        
        CGRect newRect = [self frameWithOptions:options];
        if (targetWebView.isHidden) {
            // if hidden add padding
            newRect.origin = CGPointMake(newRect.origin.x + viewPadder, newRect.origin.y);
        }
        
        targetWebView.frame = newRect;
        
        // NSLog(@"view resized! %@", targetWebView);
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];
        
        
    } else {
        // NSLog(@"view not found!");
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"view not found!"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
    }
}


- (int)getWeakLinker:(NSString*)myString ofType:(NSString*)type
{
    // do tests to get correct int (we read in as string pointer but infact we are unaware of the var type)
    int i;
    
    if (!myString || !type) {
        // got null value in method params
        return i = 0;
    }
    
    // NSLog(@"try link : %@ for type: %@", myString, type);

    
    // get Device width and height
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    
    
    
    // test for percentage
    NSArray *percentTest = [self percentTest:myString];
    
    if (percentTest) {
        // it was a percent do calculation and assign value
        
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
            // we have a float, check our float range and convert to int
            
            float floatValue = [myString floatValue];
            if (floatValue < 1.0) {
                if ([type isEqualToString:@"width"] || [type isEqualToString:@"left"] || [type isEqualToString:@"right"]) {
                    i = (floatValue * screenWidth);
                } else if ([type isEqualToString:@"height"] || [type isEqualToString:@"top"] || [type isEqualToString:@"bottom"]) {
                    i = (floatValue * screenHeight);
                } else {
                    //invalid type - not supported
                    i = 0;
                }
            } else {
                // not good float value - defaults to 0
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
         
- (BOOL) validateUrl: (NSString *) candidate {
    NSString* lowerCased = [candidate lowercaseString];
    return [lowerCased hasPrefix:@"http://"] || [lowerCased hasPrefix:@"https://"];
}
         
- (BOOL)floatTest:(NSString*)myString
{
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

- (NSArray*)percentTest:(NSString*)myString
{
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


- (void)createView:(NSArray*)arguments withDict:(NSDictionary*)options 
{
    
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName      = [arguments objectAtIndex:1];    
    
    [viewLoadedCallbackId setObject:callbackId forKey:@"updateCallback"];
    NSLog(@"[WizViewManagerPlugin] ******* createView name:  %@ withOptions: %@", viewName, options);

    UIWebView *newWizView;
    if (options) {
       
        NSString *src               = [options objectForKey:@"src"];
        if (!src) {
            // default
            src = @"";
        }
        
        int _height                 = [[options objectForKey:@"height"] intValue];
        if (!_height) {
            // default
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            _height = screenRect.size.height;
        }
        
        int _width                  = [[options objectForKey:@"width"] intValue];
        if (!_width) {
            // default
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            _width = screenRect.size.width;
        }
        
        int _x                      = [[options objectForKey:@"x"] intValue];
        if (!_x) {
            // default
            _x = 0;
        }
        
        int _y                      = [[options objectForKey:@"y"] intValue];
        if (!_y) {
            // default
            _y = 0;
        }
        
        
        CGRect newRect              = CGRectMake(_x, _y, _width, _height);
        
        // create new wizView
        newWizView = [[WizWebView alloc] createNewInstanceViewFromManager:self newBounds:newRect sourceToLoad:src];
        
        // add view name to our wizard view list
        [wizViewList setObject:newWizView forKey:viewName];
        
        // move view out of display
        [newWizView setFrame:CGRectMake(
                                        newWizView.frame.origin.x + viewPadder,
                                        newWizView.frame.origin.y,
                                        newWizView.frame.size.width,
                                        newWizView.frame.size.height
                                        )];
        [newWizView setHidden:TRUE];
        
        // add view to parent webview
        [self.webView.superview addSubview:newWizView];
        
        // set a background colour if given one
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
        
        // create new wizView
        newWizView = [[WizWebView alloc] createNewInstanceViewFromManager:self newBounds:screenRect sourceToLoad:@""];
        
        // add view name to our wizard view list
        [wizViewList setObject:newWizView forKey:viewName];
        
        
        // move view out of display
        [newWizView setFrame:CGRectMake(
                                     newWizView.frame.origin.x + viewPadder,
                                     newWizView.frame.origin.y,
                                     newWizView.frame.size.width,
                                     newWizView.frame.size.height
                                     )];
        
        // add view to parent webview
        [self.webView.superview addSubview:newWizView];
    }

    NSLog(@"[WizViewManagerPlugin] ******* current views... %@", wizViewList);

    // callbacks handled after content is loaded into wizWebView
    
}


- (void)hideView:(NSArray*)arguments withDict:(NSDictionary*)options {
        
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSLog(@"START hideView with callback :  %@", callbackId);
    NSString* viewName = [arguments objectAtIndex:1];
    
    CDVPluginResult* pluginResultOK = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    if ([wizViewList objectForKey:viewName]) {
        UIWebView* targetWebView = [wizViewList objectForKey:viewName]; 
        
        NSLog(@"[WizViewManager] ******* hideView animating Views : %@ is hidden? %i", isAnimating, !targetWebView.isHidden);

        
        if (!targetWebView.isHidden || [isAnimating objectForKey:viewName]) {
                       
            if ([isAnimating objectForKey:viewName]) {
                // view is animating - stop current animation can release previous callback
                //[isAnimating removeObjectForKey:viewName];

                NSLog(@"[WizViewManager] ******* hideView hideViewCallbackId %@", self.hideViewCallbackId);
                NSLog(@"[WizViewManager] ******* hideView showViewCallbackId %@", self.showViewCallbackId);
                if (self.hideViewCallbackId.length > 0) {
                    NSLog(@"[WizViewManager] ******* hideView, callback to hide - %@", self.hideViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.hideViewCallbackId]];
                    self.hideViewCallbackId = nil;
                    // we are hiding when hiding, exit.
                    NSLog(@"returning - already hiding animation");
                    return;
                }
                if (self.showViewCallbackId.length > 0) {
                    NSLog(@"[WizViewManager] ******* showView, callback to show - %@", self.showViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.showViewCallbackId]];
                    self.showViewCallbackId = nil;
                }
                
            }
            
            // about to animate (even if we are not) so add to animate store
            // [isAnimating setObject:targetWebView forKey:viewName];
            
            self.hideViewCallbackId = callbackId;

            if (options) 
            {
                NSDictionary* animationDict = [options objectForKey:@"animation"];
                
                if ( animationDict ) {
                    
                    NSString* type               = [animationDict objectForKey:@"type"];
                    int animateTimeinMilliSecs   = [[animationDict objectForKey:@"duration"] intValue];
                    CGFloat animateTime          = (CGFloat)animateTimeinMilliSecs / 1000;
                    if (!animateTime) {
                        //default
                        animateTime = 0.3f;
                    }
                    // NSLog(@"[WizViewManager] ******* hideView animateTime : %f ", animateTime);
                    if (!type) {
                        
                        // default
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
                        // not found do "none"
                        [self hideWithNoAnimation:targetWebView];
                        // no animate so remove from animate store
                        [isAnimating removeObjectForKey:viewName];
                    }
                    
                } else {
                    // not found do "none"
                    [self hideWithNoAnimation:targetWebView];
                    // no animate so remove from animate store
                    [isAnimating removeObjectForKey:viewName];
                }
                
            } else {
                // not found do "none"
                [self hideWithNoAnimation:targetWebView];
                // no animate so remove from animate store
                [isAnimating removeObjectForKey:viewName];
            }
            
        } else {
            // target already hidden do nothing
            NSLog(@"[WizViewManager] ******* target already hidden! ");
            [self writeJavascript: [pluginResultOK toSuccessCallbackString:callbackId]];
        }

        // Other callbacks come from after view is added to animation object
        
        

    } else {
        
        CDVPluginResult* pluginResultErr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResultErr toErrorCallbackString:callbackId]];
        
    }
}


- (void)showView:(NSArray*)arguments withDict:(NSDictionary*)options {
        
    // assign arguments
    NSString* callbackId = [arguments objectAtIndex:0];
    NSLog(@"START showView with callback :  %@", callbackId);
    NSString* viewName = [arguments objectAtIndex:1];
    
    CDVPluginResult* pluginResultOK = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    CDVPluginResult* pluginResultERROR = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];


    
    if ([wizViewList objectForKey:viewName]) {
        UIWebView* targetWebView = [wizViewList objectForKey:viewName]; 
        
        
        NSLog(@"[WizViewManager] ******* showView animating object : %@ is hidden? %i", isAnimating, targetWebView.isHidden); 
        

        
        if (targetWebView.isHidden || [isAnimating objectForKey:viewName]) {
            
            if ([isAnimating objectForKey:viewName]) {
                // view is animating - stop current animation can release previous callback
                
                //[isAnimating removeObjectForKey:viewName];

                
                NSLog(@"[WizViewManager] ******* showView hideViewCallbackId %@", self.hideViewCallbackId);
                NSLog(@"[WizViewManager] ******* showView showViewCallbackId %@", self.showViewCallbackId);
                if (self.hideViewCallbackId.length > 0) {
                    NSLog(@"[WizViewManager] ******* showView, callback to hide - %@", self.hideViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.hideViewCallbackId]];
                    self.hideViewCallbackId = nil;
                }
                if (self.showViewCallbackId.length > 0) {
                    NSLog(@"[WizViewManager] ******* showView, callback to show - %@", self.showViewCallbackId);
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:self.showViewCallbackId]];
                    self.showViewCallbackId = nil;
                    // we are showing when showing, exit.
                    NSLog(@"returning - already showing animation");
                    return;
                }
                
            }
                
            
            self.showViewCallbackId = callbackId;
            

            
           
            if (options) 
            {
                
                NSDictionary* animationDict = [options objectForKey:@"animation"];
                
                if ( animationDict ) {
                    
                    NSLog(@"[WizViewManager] ******* with options : %@ ", options);
                    NSString* type               = [animationDict objectForKey:@"type"];
                    int animateTimeinMilliSecs   = [[animationDict objectForKey:@"duration"] intValue];
                    CGFloat animateTime          = (CGFloat)animateTimeinMilliSecs / 1000;
                    if (!animateTime) {
                        //default
                        animateTime = 0.3f;
                    }
                    // NSLog(@"[WizViewManager] ******* showView animateTime : %f ", animateTime);
                    
                    if (!type) {
                        
                        // default
                        [self showWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"zoomIn"]) {
                        
                        [self showWithZoomInAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"fadeIn"]) {
                        
                        [self showWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromLeft"]) {
                        
                        [self showWithSlideInFromLeftAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromRight"]) {
                        
                        [self showWithSlideInFromRightAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromTop"]) {
                        
                        [self showWithSlideInFromTopAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromBottom"]) {
                        
                        [self showWithSlideInFromBottomAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState showViewCallbackId:callbackId viewName:viewName];
                        
                    } else {
                        // not found do "none"
                        [self showWithNoAnimation:targetWebView];
                        // no animate so remove from animate store
                        [isAnimating removeObjectForKey:viewName];
                        [self writeJavascript: [pluginResultOK toSuccessCallbackString:callbackId]];
                        self.showViewCallbackId = nil;
                    }
                    
                } else {
                    // not found do "none"
                    [self showWithNoAnimation:targetWebView];
                    // no animate so remove from animate store
                    [isAnimating removeObjectForKey:viewName];
                    [self writeJavascript: [pluginResultOK toSuccessCallbackString:callbackId]];
                    self.showViewCallbackId = nil;
                }

                
            } else {
                // not found do "none"
                [self showWithNoAnimation:targetWebView];
                // no animate so remove from animate store
                [isAnimating removeObjectForKey:viewName];
                [self writeJavascript: [pluginResultOK toSuccessCallbackString:callbackId]];
                self.showViewCallbackId = nil;
            }
                
        } else {
            // target already showing
            NSLog(@"[WizViewManager] ******* target already shown! "); 
            [self writeJavascript: [pluginResultERROR toErrorCallbackString:callbackId]];
            self.showViewCallbackId = nil;
            
        }

        
    } else {
                
        CDVPluginResult* pluginResultErr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResultErr toErrorCallbackString:callbackId]];
    }
}



/**
 
 COLOUR CALCULATOR
 
 
 **/

- (UIColor *) colorWithHexString: (NSString *) hexString
{
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
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length 
{
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}





/**
 
 ANIMATION METHODS
 
 **/


- (void) showViewCallbackMethod:(NSString* )callbackId viewName:(NSString* )viewName {
    
    if (self.showViewCallbackId.length > 0) {
        // we are still animating without iteruption so continue callback
        NSString* callback = self.showViewCallbackId;
        self.showViewCallbackId = nil;
        NSLog(@"[SHOW] callback to %@", callback);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:callback]];
    }

}



- (void) showWithNoAnimation:(UIView *)view
{
    // move view into display       
    [view setFrame:CGRectMake(
                              view.frame.origin.x - viewPadder,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    view.alpha = 1.0;
    
}

- (void) hideWithNoAnimation:(UIView *)view
{
    view.alpha = 0.0;
    // move view out of display
    [view setFrame:CGRectMake(
                              view.frame.origin.x + viewPadder,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    self.hideViewCallbackId = nil;
    
}


- (void) showWithSlideInFromTopAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName
{
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    // move view to bottom of visible display      
    [view setFrame:CGRectMake(
                              view.frame.origin.x - viewPadder,
                              view.frame.origin.y - screenHeight,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    view.alpha = 1.0;
    // now return the view to normal dimension, animating this tranformation
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, view.frame.origin.x, screenHeight);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
}

- (void) hideWithSlideOutToTopAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName
{
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, view.frame.origin.x, -screenHeight);
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

- (void) showWithSlideInFromBottomAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName
{
    
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
                         view.transform = CGAffineTransformTranslate(view.transform, view.frame.origin.x, -screenHeight);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
}

- (void) hideWithSlideOutToBottomAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName
{
    
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, view.frame.origin.x, screenHeight);
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

- (void) showWithSlideInFromRightAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName
{
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    // move view to right of visible display      
    [view setFrame:CGRectMake(
                              (view.frame.origin.x - viewPadder) + screenWidth,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    view.alpha = 1.0;
    // now return the view to normal dimension, animating this tranformation
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, -screenWidth, view.frame.origin.y);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
}

- (void) hideWithSlideOutToRightAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName
{
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, screenWidth, view.frame.origin.y);
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


- (void) showWithSlideInFromLeftAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString *)callbackId viewName:(NSString *)viewName
{

    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    // move view to left of visible display      
    [view setFrame:CGRectMake(
                              (view.frame.origin.x - viewPadder) - screenWidth,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    [view setAlpha:1.0];
    // now return the view to normal dimension, animating this tranformation
    
   
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, screenWidth, view.frame.origin.y);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
     
}

- (void) hideWithSlideOutToLeftAnimation:(UIView *)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName
{
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    [UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.transform = CGAffineTransformTranslate(view.transform, -screenWidth, view.frame.origin.y);
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

- (void) showWithZoomInAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString *)viewName
{

    // first reduce the view to 1/100th of its original dimension
    CGAffineTransform trans = CGAffineTransformScale(view.transform, 0.01, 0.01);
    view.transform = trans;	// do it instantly, no animation
    // move view into display       
    [view setFrame:CGRectMake(
               view.frame.origin.x - viewPadder,
               view.frame.origin.y,
               view.frame.size.width,
               view.frame.size.height
               )];
    [view setHidden:FALSE];
    // [self addSubview:view];
    // now return the view to normal dimension, animating this tranformation
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





- (void) hideWithZoomOutAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName
{
    
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


- (void) showWithFadeAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString *)viewName
{
    
    WizLog(@"SHOW FADE view is %@, %@", view, viewName);

    // check frame x co ordinate is the same (in case of mid animation), if different we need to reset frame

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
    
    // about to animate so add to animate store
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

- (void) hideWithFadeAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName
{
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
- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    return [self.webviewDelegate webViewDidStartLoad:theWebView];
}

- (void) webViewDidFinishLoad:(UIWebView*)theWebView 
{
    return [self.webviewDelegate webViewDidFinishLoad:theWebView];
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error 
{
    return [self.webviewDelegate webView:theWebView didFailLoadWithError:error];
}

-(BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    

    BOOL superValue = [ self.webviewDelegate webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType ];

    // If get this request reboot...
    NSString *requestString = [[request URL] absoluteString];
    NSArray* prefixer = [requestString componentsSeparatedByString:@":"];
        
    // do insensitive compare to support SDK >5
    if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"rebootapp"] == 0) {
        
        // perform restart a second later
        [self performSelector:@selector(timedRestart) withObject:theWebView afterDelay:1.0f];
        
        return NO;
		
	} else if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"wizMessageView"] == 0) {
        
        NSArray *components = [requestString componentsSeparatedByString:@"://"];
        NSString *messageData = [[NSString alloc] initWithString:(NSString*)[components objectAtIndex:1]];
        
        NSRange range = [messageData rangeOfString:@"?"];
        
        NSString *targetView = [messageData substringToIndex:range.location];
        
        NSLog(@"[WizWebView] ******* targetView is:  %@", targetView );
        
        int targetLength = targetView.length;
        
        NSString *postData = [messageData substringFromIndex:targetLength+1];
        
        // NSLog(@"[AppDelegate wizMessageView()] ******* postData is:  %@", postData );
        
        NSMutableDictionary * viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];
        
        if ([viewList objectForKey:targetView]) {
            UIWebView* targetWebView = [viewList objectForKey:targetView]; 
            NSString *postDataEscaped = [postData stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
            [targetWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"wizMessageReceiver('%@');", postDataEscaped]];
            
            // WizLog(@"[AppDelegate wizMessageView()] ******* current views... %@", viewList);
        }
        
        [messageData release];
        messageData = nil;
        [viewList release];
        
        
        return NO;
        
 	} else {
        // let Cordova handle everything else
        return superValue;
    }

}


-(void) timedRestart:(UIWebView*)theWebView
{
    // gives time for our JS method to execute splash
    
    
    // remove all views
    NSArray *allKeys = [NSArray arrayWithArray:[wizViewList allKeys]];
    
    for (int i = 0; i<[allKeys count]; i++) {
        
        if (![[allKeys objectAtIndex:i] isEqualToString:@"mainView"]) {
            [self removeView:[NSArray arrayWithObjects:@"", [allKeys objectAtIndex:i], nil] withDict:NULL];
        }
        
    }
    
    // resize mainView to normal
    [self setLayout:[NSArray arrayWithObjects:@"", @"mainView", nil] withDict:NULL];
    
    [theWebView reload];
}

@end