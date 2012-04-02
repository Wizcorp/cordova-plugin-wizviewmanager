/* AppDelegate - EXAMPLE
 *
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2012
 * @file AppDelegate.m
 *
 */

#import "AppDelegate.h"
#import "WizViewManagerPlugin.h"

#ifdef PHONEGAP_FRAMEWORK
	#import <PhoneGap/PhoneGapViewController.h>
#else
	#import "PhoneGapViewController.h"
#endif

@implementation AppDelegate




/*
 * Start Loading Request
 * This is where most of the magic happens... We take the request(s) and process the response.
 * From here we can re direct links and other protocalls to different internal methods.
 */
- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    // If get this request reboot...
    NSString *requestString = [[request URL] absoluteString];
    
    
    // do insensitive compare to support SDK >5
    if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"wizMessageView"] == 0) {
        
        NSArray* components = [requestString componentsSeparatedByString:@"://"];
        NSString* messageData = (NSString*)[components objectAtIndex:1];
        
        NSRange range = [messageData rangeOfString:@"?"];
        
        NSString* targetView = [messageData substringToIndex:range.location];
        
        WizLog(@"[AppDelegate wizMessageView()] ******* targetView is:  %@", targetView );
        
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
    
    
	return [ super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType ];
}



@end
