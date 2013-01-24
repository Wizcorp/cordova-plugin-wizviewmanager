/* WizViewManager - Handle Popup UIViews and communtications.
 *
 * @author Ally Ogilvie
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file WizViewManager.h for PhoneGap
 *
 */ 

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface WizViewManagerPlugin : CDVPlugin <UIWebViewDelegate> {
    
    CGRect originalWebViewBounds;

}

@property (nonatomic, retain) NSString *showViewCallbackId;
@property (nonatomic, retain) NSString *hideViewCallbackId;
@property (nonatomic, readwrite, assign) id<UIWebViewDelegate> webviewDelegate;
@property (nonatomic, retain) UIView *canvasView;

+ (NSMutableDictionary *)getViews;
+ (NSMutableDictionary *)getViewLoadedCallbackId;
+ (WizViewManagerPlugin *)instance;

/**
 
 PHONEGAP HOOKS
 
 **/
- (void)createView:(CDVInvokedUrlCommand*)command;
- (void)hideView:(CDVInvokedUrlCommand*)command;
- (void)showView:(CDVInvokedUrlCommand*)command;
- (void)updateView:(CDVInvokedUrlCommand*)command;
- (void)load:(CDVInvokedUrlCommand*)command;;
- (void)removeView:(CDVInvokedUrlCommand*)command;
- (void)setLayout:(CDVInvokedUrlCommand*)command;


/**
 
 INTERNALS
 
 **/
- (void)sendMessage:(NSString*)viewName withMessage:(NSString*)message;
- (void)showWebView:(CDVInvokedUrlCommand*)command;
- (void)showCanvasView:(CDVInvokedUrlCommand*)command;
- (void)hideWebView:(CDVInvokedUrlCommand*)command;
- (void)hideCanvasView:(CDVInvokedUrlCommand*)command;
- (void)updateViewList;

/**
 
 ANIMATION METHODS
 
 **/
- (void) hideWithNoAnimation:(UIView*)view;
- (void) showWithNoAnimation:(UIView*)view;

- (void) showWithZoomInAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString*)viewName;
- (void) hideWithZoomOutAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString*)viewName;
- (void) showWithFadeAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString*)viewName;
- (void) hideWithFadeAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString*)viewName;
- (void) showWithSlideInFromLeftAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString*)viewName;
- (void) hideWithSlideOutToLeftAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString*)viewName;
- (void) showWithSlideInFromRightAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString*)viewName;
- (void) hideWithSlideOutToRightAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString*)viewName;
- (void) showWithSlideInFromTopAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString*)viewName;
- (void) hideWithSlideOutToTopAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString*)viewName;
- (void) showWithSlideInFromBottomAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option showViewCallbackId:(NSString*)callbackId viewName:(NSString*)viewName;
- (void) hideWithSlideOutToBottomAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option viewName:(NSString*)viewName;

@end