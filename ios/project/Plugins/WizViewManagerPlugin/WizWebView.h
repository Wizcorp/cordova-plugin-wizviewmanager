/* WizWebView - Creates Instance of wizard UIWebView.
 *
 * @author Ally Ogilvie
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file WizWebView.h for PhoneGap
 *
 *
 */

#import <Foundation/Foundation.h>
#ifdef CORDOVA_FRAMEWORK
#import <Cordova/CDVPlugin.h>
#else
#import "CDVPlugin.h"
#endif

@interface WizWebView : UIWebView <UIWebViewDelegate> {

}

@property (nonatomic, retain) UIWebView *wizView;

-(UIWebView *)createNewInstanceView:(CDVPlugin*)myViewManager newBounds:(CGRect)webViewBounds sourceToLoad:(NSString*)src;


@end
