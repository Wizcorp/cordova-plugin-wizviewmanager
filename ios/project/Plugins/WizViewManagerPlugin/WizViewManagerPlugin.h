/* WizViewManager - Handle Popup UIViews and communtications.
 *
 * @author Ally Ogilvie
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file WizViewManager.h for PhoneGap
 *
 */ 

#import <Foundation/Foundation.h>
#ifdef CORDOVA_FRAMEWORK
#import <Cordova/CDVPlugin.h>
#else
#import "CDVPlugin.h"
#endif

@interface WizViewManagerPlugin : CDVPlugin <UIWebViewDelegate> {
    
    CGRect originalWebViewBounds;

}

@property (nonatomic, retain) NSString* showViewCallbackId;
@property (nonatomic, retain) NSString* hideViewCallbackId;
@property (nonatomic, readwrite, assign) id<UIWebViewDelegate> webviewDelegate;


+ (NSMutableDictionary *)getViews;
+ (NSMutableDictionary *)getViewLoadedCallbackId;


- (void)createView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)hideView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)showView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)updateView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)load:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)removeView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)setLayout:(NSArray*)arguments withDict:(NSDictionary*)options;



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

/*
#ifdef CORDOVA_FRAMEWORK
#import <Cordova/CDVViewController.h>
#else
#import "CDVViewController.h"
#endif
@interface CDVViewController(urlListener)


-(BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;

@end
*/