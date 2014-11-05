/* WizWKWebView - Creates Instance of wizard WKWebView.
 *
 * @author aogilvie@wizcorp.jp
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2014
 * @file WizWKWebView.h for PhoneGap
 *
 */ 

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <Cordova/CDVPlugin.h>

@interface WizWKWebView : NSObject <WKUIDelegate, WKNavigationDelegate> {
}

@property (nonatomic, retain) WKWebView *wizView;
@property (nonatomic, retain) NSString *viewName;

- (WKWebView *)createNewInstanceViewFromManager:(CDVPlugin *)myViewManager newBounds:(CGRect)webViewBounds viewName:(NSString *)name sourceToLoad:(NSString *)src withOptions:(NSDictionary *)options;

@end
