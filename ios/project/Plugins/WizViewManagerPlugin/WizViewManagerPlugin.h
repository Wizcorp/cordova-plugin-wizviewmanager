/* WizViewManager - Handle Popup UIViews and communtications.
 *
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file WizViewManager.h for PhoneGap
 *
 */ 

#import <Foundation/Foundation.h>
#ifdef PHONEGAP_FRAMEWORK
#import <PhoneGap/PGPlugin.h>
#else
#import "PGPlugin.h"
#endif

@interface WizViewManagerPlugin : PGPlugin <UIWebViewDelegate> {
    
    CGRect originalWebViewBounds;

}

@property (nonatomic, copy) NSString* showViewCallbackId;


+ (NSMutableDictionary *)getViews;
+ (NSMutableDictionary *)getViewLoadedCallbackId;
+ (void) pong;


- (void)initPing:(NSArray*)arguments withDict:(NSDictionary*)options;

- (void)createView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)hideView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)showView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)updateView:(NSArray*)arguments withDict:(NSDictionary*)options;
- (void)removeView:(NSArray*)arguments withDict:(NSDictionary*)options;



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
