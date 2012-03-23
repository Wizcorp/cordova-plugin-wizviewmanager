/* WizWebView - Creates Instance of wizard UIWebView.
 *
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file WizWebView.h for PhoneGap
 *
 */ 

#import <Foundation/Foundation.h>
#ifdef PHONEGAP_FRAMEWORK
#import <PhoneGap/PGPlugin.h>
#else
#import "PGPlugin.h"
#endif

@interface WizWebView : UIWebView <UIWebViewDelegate> {

}

@property (nonatomic, retain) UIWebView *wizView;

-(UIWebView *)createNewInstanceView:(PGPlugin*)myViewManager newBounds:(CGRect)webViewBounds sourceToLoad:(NSString*)src;


@end
