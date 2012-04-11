/* WizViewManager - Handle Popup UIViews and communications.
 *
 * @author Ally Ogilvie
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file WizViewManager.m for PhoneGap
 *
 *
 */

#import "WizViewManagerPlugin.h"
#import "WizDebugLog.h"
#import "WizWebView.h"


@implementation WizViewManagerPlugin

@synthesize showViewCallbackId;

static NSMutableDictionary *wizViewList = nil;
static CGFloat viewPadder = 9999.0f;
static NSMutableDictionary *viewLoadedCallbackId = nil;
static NSMutableDictionary *isAnimating = nil;

-(PGPlugin*) initWithWebView:(UIWebView*)theWebView
{

    self = (WizViewManagerPlugin*)[super initWithWebView:theWebView];
    if (self) 
	{
		originalWebViewBounds = theWebView.bounds;
        
    }
    
    // this holds all our views, first we add MainView to our view list by default
    wizViewList = [[NSMutableDictionary alloc ] initWithObjectsAndKeys: theWebView, @"mainView", nil];
    
    // this holds callbacks for each view
    viewLoadedCallbackId = [[NSMutableDictionary alloc ] init];
    
    // this holds any views that are animating
    isAnimating = [[NSMutableDictionary alloc ] init];

    
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


- (void)updateView:(NSArray*)arguments withDict:(NSDictionary*)options 
{
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName    = [arguments objectAtIndex:1];
    
    [viewLoadedCallbackId setObject:callbackId forKey:@"viewLoadedCallback"];
    
    WizLog(@"[WizViewManager] ******* updateView name : %@ with options %@ ", viewName, options); 
    
    // wait for callback
    /*
    PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:YES];
    [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];
    */
    
    if (options) 
	{
            
        // search for view
        if ([wizViewList objectForKey:viewName]) {
            UIWebView* targetWebView = [wizViewList objectForKey:viewName]; 
            
            NSString* src               = [options objectForKey:@"src"];
            if (src) {
                
                
                NSURL *candidateURL = [NSURL URLWithString:src];
                if (candidateURL && candidateURL.scheme && candidateURL.host) {
                    // candidate is a well-formed url with:
                    //  - a scheme (like http://)
                    //  - a host (like stackoverflow.com)
                                        
                    WizLog(@"[WizViewManager] ******* updateView with URL");
                    [targetWebView loadRequest:[NSURLRequest requestWithURL:candidateURL]];
                    
                    
                } else {
                
                    WizLog(@"[WizViewManager] ******* updateView with local file");
                    
                    // load new source
                    NSString *fileString = src;
                
                    NSString *newHTMLString = [[NSString alloc] initWithContentsOfFile: fileString encoding: NSUTF8StringEncoding error: NULL];
                
                    NSURL *newURL = [[NSURL alloc] initFileURLWithPath: fileString];
                
                    [targetWebView loadHTMLString: newHTMLString baseURL: newURL];
                    
                    [newHTMLString release];
                    [newURL release];
                }
                
                
            }
            

            
            
            
            /*
            PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
            [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];
             */
            
        } else {
            
            PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:@"error - view not found"];
            [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
        
        }
 
    } else {
        
        PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:@"error - nothing to update"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
        
    }
      
}   


- (void)removeView:(NSArray*)arguments withDict:(NSDictionary*)options
{
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName    = [arguments objectAtIndex:1];
    
    WizLog(@"[WizViewManager] ******* removeView name : %@ ", viewName);
    
    // search for view
    if ([wizViewList objectForKey:viewName]) {
        UIWebView* targetWebView = [wizViewList objectForKey:viewName]; 
        
        // remove the view from wizViewList
        [wizViewList removeObjectForKey:viewName];
        
        // remove the view!
        [targetWebView removeFromSuperview];
        targetWebView.delegate = nil;
        targetWebView = nil;
        [targetWebView release];

        
        PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];
        
        
         WizLog(@"[WizViewManager] ******* removeView views left : %@ ", wizViewList);
    } else {
        
        PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
    }
    
}

- (void)createView:(NSArray*)arguments withDict:(NSDictionary*)options 
{
    
    
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString *viewName    = [arguments objectAtIndex:1];
    
    
    // [viewLoadedCallbackId setObject:callbackId forKey:@"updateCallback"];
    WizLog(@"[WizViewManagerPlugin] ******* createView name:  %@ withOptions: %@", viewName, options);


    WizWebView* _WizWebView = [WizWebView alloc];
    
    if (options) 
	{
       
        NSString* src               = [options objectForKey:@"src"];
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
        UIWebView *newWizView = [_WizWebView createNewInstanceView:self newBounds:newRect sourceToLoad:src];
        
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
        
        
        
        
    } else {
        // OK default settings apply
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        
        // create new wizView
        UIWebView *newWizView = [_WizWebView createNewInstanceView:self newBounds:screenRect sourceToLoad:@""];
        
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

    WizLog(@"[WizViewManagerPlugin] ******* current views... %@", wizViewList);

    
    PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
    [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];
     
    
}


- (void)hideView:(NSArray*)arguments withDict:(NSDictionary*)options {
        
    // assign arguments
    NSString *callbackId    = [arguments objectAtIndex:0];
    NSString* viewName = [arguments objectAtIndex:1];
    
    
    if ([wizViewList objectForKey:viewName]) {
        UIWebView* targetWebView = [wizViewList objectForKey:viewName]; 
        
        if (!targetWebView.isHidden) {
            
            if (isAnimating) {
                if ([isAnimating objectForKey:viewName]) {
                    // view is animating - error!
                    
                    // we are already animating something so give error...
                    PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR];
                    NSString* returnString = [NSString stringWithFormat:@"ERROR: View: %@ is Animating. Please wait for callback!", viewName];
                    WizLog(@"[WizViewManager] ******* %@", returnString);
                    [self writeJavascript: [pluginResult toErrorCallbackString:returnString]];
                    return;
                    
                }
                
            }
            
            if (options) 
            {
                NSDictionary* animationDict = [options objectForKey:@"animation"];
                
                if ( animationDict ) {
                    
                    WizLog(@"[WizViewManager] ******* hideView with options : %@ ", options);
                    NSString* type               = [animationDict objectForKey:@"type"];
                    int animateTimeinMilliSecs   = [[animationDict objectForKey:@"duration"] intValue];
                    CGFloat animateTime          = (CGFloat)animateTimeinMilliSecs / 1000;
                    if (!animateTime) {
                        //default
                        animateTime = 0.3f;
                    }
                    // WizLog(@"[WizViewManager] ******* hideView animateTime : %f ", animateTime);
                    if (!type) {
                        
                        // default
                        [self hideWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut viewName:viewName];
                        
                    } else if ([type isEqualToString:@"zoomOut"]) {
                        
                        [self hideWithZoomOutAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut viewName:viewName];
                        
                    } else if ([type isEqualToString:@"fadeOut"]) {
                        
                        [self hideWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToLeft"]) {
                        
                        [self hideWithSlideOutToLeftAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToRight"]) {
                        
                        [self hideWithSlideOutToRightAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToTop"]) {
                        
                        [self hideWithSlideOutToTopAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideOutToBottom"]) {
                        
                        [self hideWithSlideOutToBottomAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseOut viewName:viewName];
                        
                    } else {
                        // not found do "none"
                        [self hideWithNoAnimation:targetWebView];
                    }
                    
                } else {
                    // not found do "none"
                    [self hideWithNoAnimation:targetWebView];
                }
                
            } else {
                // not found do "none"
                [self hideWithNoAnimation:targetWebView];
            }
            
        } else {
            // target already hidden do nothing
            WizLog(@"[WizViewManager] ******* target already hidden! "); 
        }

        
        
        WizLog(@"[WizViewManager] ******* hideView name : %@ targetWebView view : %@", viewName, targetWebView); 
        
        // We call straight back because we assume that as we hide the view behind does not want to wait
        PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
        [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];

    } else {
        
        PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
        
    }
}


- (void)showView:(NSArray*)arguments withDict:(NSDictionary*)options {
        
    // assign arguments
    NSString* callbackId = [arguments objectAtIndex:0];
    NSString* viewName = [arguments objectAtIndex:1];
    

    
    if ([wizViewList objectForKey:viewName]) {
        UIWebView* targetWebView = [wizViewList objectForKey:viewName]; 
        
        
        WizLog(@"[WizViewManager] ******* showView: %@ targetWebView Info: %@", viewName, targetWebView); 
        

        
        if (targetWebView.isHidden) {
            
            if (isAnimating) {
                if ([isAnimating objectForKey:viewName]) {
                    // view is animating - error!
                    
                    // we are already animating something so give error...
                    PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR];
                    NSString* returnString = [NSString stringWithFormat:@"ERROR: View: %@ is Animating. Please wait for callback!", viewName];
                    WizLog(@"[WizViewManager] ******* %@", returnString);
                    [self writeJavascript: [pluginResult toErrorCallbackString:returnString]];
                    return;
                    
                }
                
            }
            
            showViewCallbackId = callbackId;
            
            // about to animate so add to animate store
            [isAnimating setObject:targetWebView forKey:viewName];
            
           
            if (options) 
            {
                
                NSDictionary* animationDict = [options objectForKey:@"animation"];
                
                if ( animationDict ) {
                    
                    WizLog(@"[WizViewManager] ******* with options : %@ ", options);
                    NSString* type               = [animationDict objectForKey:@"type"];
                    int animateTimeinMilliSecs   = [[animationDict objectForKey:@"duration"] intValue];
                    CGFloat animateTime          = (CGFloat)animateTimeinMilliSecs / 1000;
                    if (!animateTime) {
                        //default
                        animateTime = 0.3f;
                    }
                    // WizLog(@"[WizViewManager] ******* showView animateTime : %f ", animateTime);
                    
                    if (!type) {
                        
                        // default
                        [self showWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"zoomIn"]) {
                        
                        [self showWithZoomInAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"fadeIn"]) {
                        
                        [self showWithFadeAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromLeft"]) {
                        
                        [self showWithSlideInFromLeftAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromRight"]) {
                        
                        [self showWithSlideInFromRightAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromTop"]) {
                        
                        [self showWithSlideInFromTopAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn showViewCallbackId:callbackId viewName:viewName];
                        
                    } else if ([type isEqualToString:@"slideInFromBottom"]) {
                        
                        [self showWithSlideInFromBottomAnimation:targetWebView duration:animateTime option:UIViewAnimationOptionCurveEaseIn showViewCallbackId:callbackId viewName:viewName];
                        
                    } else {
                        // not found do "none"
                        [self showWithNoAnimation:targetWebView];
                        // no animate so remove from animate store
                        [isAnimating removeObjectForKey:viewName];
                    }
                    
                } else {
                    // not found do "none"
                    [self showWithNoAnimation:targetWebView];
                    // no animate so remove from animate store
                    [isAnimating removeObjectForKey:viewName];
                }

                
            } else {
                // not found do "none"
                [self showWithNoAnimation:targetWebView];
                // no animate so remove from animate store
                [isAnimating removeObjectForKey:viewName];
            }
                
        } else {
            // target already showing
            WizLog(@"[WizViewManager] ******* target already shown! "); 
            PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
            [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
        }

        
    } else {
                
        PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_ERROR messageAsString:@"error - view not found"];
        [self writeJavascript: [pluginResult toErrorCallbackString:callbackId]];
    }
}











/**
 
 ANIMATION METHODS
 
 **/


- (void) showViewCallbackMethod:(NSString* )callbackId viewName:(NSString* )viewName {
    // WizLog(@"[WizViewManager] ******* showViewCallbackId options : %@", callbackId);
    // WizLog(@"[WizViewManagerPlugin] ******* current views... %@", wizViewList);
    
    // finished animation remove from animate store
    [isAnimating removeObjectForKey:viewName];
    
    PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
    [self writeJavascript: [pluginResult toSuccessCallbackString:callbackId]];
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
    

    
    PluginResult* pluginResult = [PluginResult resultWithStatus:PGCommandStatus_OK];
    [self writeJavascript: [pluginResult toSuccessCallbackString:showViewCallbackId]];
    
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
                         if (callbackId != nil) {
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
                         if (callbackId != nil) {
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
                         if (callbackId != nil) {
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
                         if (callbackId != nil) {
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
                         if (callbackId != nil) {
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
                     }];
}


- (void) showWithFadeAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString *)viewName
{

	view.alpha = 0.0;	// make the view transparent
	// move view into display       
    [view setFrame:CGRectMake(
                              view.frame.origin.x - viewPadder,
                              view.frame.origin.y,
                              view.frame.size.width,
                              view.frame.size.height
                              )];
    [view setHidden:FALSE];
    //[self addSubview:view];	// add it
	[UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{
                         view.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         if (callbackId != nil) {
                             [self showViewCallbackMethod:callbackId viewName:viewName];
                         }
                     }];
    

}
// [self performSelector:@selector(_userLoggedIn) withObject:nil afterDelay:0.010f];

- (void) hideWithFadeAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString *)viewName
{
    
	view.alpha = 1.0;	// make the view transparent
    //[self addSubview:view];	// add it
	[UIView animateWithDuration:secs delay:0.0 options:option
                     animations:^{view.alpha = 0.0;}
                     completion:^(BOOL finished) { 
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
                         
                     }];	// animate the return to visible 
}




@end