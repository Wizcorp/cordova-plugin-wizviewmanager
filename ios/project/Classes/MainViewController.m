// add this import:
#import "WizViewManagerPlugin.h"

@implementation MainViewController

// uncomment/add this function:

 - (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
 {
     // If get this request reboot...
     NSString *requestString = [[request URL] absoluteString];
     NSArray* prefixer = [requestString componentsSeparatedByString:@":"];


     // do insensitive compare to support SDK >5
     if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"wizMessageView"] == 0) {

         NSArray* components = [requestString componentsSeparatedByString:@"://"];
         NSString* messageData = (NSString*)[components objectAtIndex:1];

         NSRange range = [messageData rangeOfString:@"?"];

         NSString* targetView = [messageData substringToIndex:range.location];

         NSLog(@"[AppDelegate wizMessageView()] ******* targetView is:  %@", targetView );

         int targetLength = targetView.length;

         NSString* postData = [messageData substringFromIndex:targetLength+1];

         // WizLog(@"[AppDelegate wizMessageView()] ******* postData is:  %@", postData );

         NSMutableDictionary * viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];




         if ([viewList objectForKey:targetView]) {
             UIWebView* targetWebView = [viewList objectForKey:targetView]; 
             NSString *postDataEscaped = [postData stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
             [targetWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"wizMessageReceiver('%@');", postDataEscaped]];

             // WizLog(@"[AppDelegate wizMessageView()] ******* current views... %@", viewList);
         }

         [viewList release];


         return NO;

 	} 
 	return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
 }

@end