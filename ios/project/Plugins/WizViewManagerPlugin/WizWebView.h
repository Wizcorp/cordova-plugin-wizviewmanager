/* WizWebView - Creates Instance of wizard UIWebView.
 *
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file WizWebView.h for PhoneGap
 *
 */ 

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface WizWebView : NSObject <UIWebViewDelegate> {

}

@property (nonatomic, retain) UIWebView *wizView;

-(UIWebView *)createNewInstanceViewFromManager:(CDVPlugin*)myViewManager newBounds:(CGRect)webViewBounds sourceToLoad:(NSString*)src;

@end
