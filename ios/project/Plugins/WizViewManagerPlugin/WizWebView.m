/* WizWebView - Creates Instance of wizard UIWebView.
 *
 * @author Ally Ogilvie 
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file WizWebView.m for PhoneGap
 *
 */ 

#import "WizWebView.h"
#import "WizViewManagerPlugin.h"

@implementation WizWebView

@synthesize wizView;

static CDVPlugin* viewManager;
static BOOL isActive = FALSE;

-(UIWebView *)createNewInstanceViewFromManager:(CDVPlugin*)myViewManager newBounds:(CGRect)webViewBounds sourceToLoad:(NSString*)src {
    
    viewManager = myViewManager;
    
    wizView = [[CDVCordovaView alloc] initWithFrame:webViewBounds];
    wizView.delegate = self;
    wizView.multipleTouchEnabled   = YES;
    wizView.autoresizesSubviews    = YES;
    wizView.hidden                 = NO;
    wizView.userInteractionEnabled = YES;
    wizView.opaque = NO;
    
    // Set scales to fit setting based on Cordova settings.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Cordova" ofType:@"plist"];
    NSMutableDictionary *cordovaConfig = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    NSNumber *scaleToFit = [cordovaConfig objectForKey:@"EnableViewportScale"];
    if ( scaleToFit ) {
        wizView.scalesPageToFit = [scaleToFit boolValue];
    } else {
        wizView.scalesPageToFit = NO;
        NSLog(@"[WizWebView] ******* WARNING  - EnableViewportScale was not specified in Cordova.plist");
    }
    
    NSLog(@"[WizWebView] ******* building new view SOURCE IS URL? - %i", [self validateUrl:src]);

    
    // load source from URI for example
    // /Users/WizardBookPro/Library/Application Support/iPhone Simulator/4.3.2/Applications/14013381-4491-42B9-8A72-30223350C81C/zombiejombie.app/www/test2_index.html
    
    if ([self validateUrl:src]) {
        // load new source
        // source is url
        NSLog(@"SOURCE IS URL %@", src);
        NSURL *newURL = [NSURL URLWithString:src];

        // JC- Setting the service type to video somehow seems to
        // disable the reuse of this connection for pipelining new
        // HTTP requests, which apparently fixes the tying of these
        // requests to the ajax connection used for the message streams
        // (which is initiated from the Javascript realm).
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:newURL];
        [request setNetworkServiceType:NSURLNetworkServiceTypeVideo];

        [wizView loadRequest:request];
        
    } else {
        NSLog(@"SOURCE NOT URL %@", src);
        NSString *fileString = src;
        
        NSString *newHTMLString = [[NSString alloc] initWithContentsOfFile: fileString encoding: NSUTF8StringEncoding error: NULL];
        
        NSURL *newURL = [[NSURL alloc] initFileURLWithPath: fileString];
        
        [wizView loadHTMLString: newHTMLString baseURL: newURL];
        
        [newHTMLString release];
        [newURL release];                    
    }

    
    wizView.bounds = webViewBounds;
    
    [wizView setFrame:CGRectMake(
                                 webViewBounds.origin.x,
                                 webViewBounds.origin.y,
                                 webViewBounds.size.width,
                                 webViewBounds.size.height
                                 )];
    
    // add this view as subview after creating instance in parent class.
    return wizView;
}

+ (BOOL) isActive {
    return isActive;
}

- (BOOL) validateUrl: (NSString *) candidate {
    NSString* lowerCased = [candidate lowercaseString];
    return [lowerCased hasPrefix:@"http://"] || [lowerCased hasPrefix:@"https://"];
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
	// view is loaded
    NSLog(@"[WizWebView] ******* view is LOADED! " );
    
    isActive = TRUE;
    
    // to send data straght to mainView onLoaded via phonegap callback
     
    NSMutableDictionary * callbackDict = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViewLoadedCallbackId]];
    
    NSLog(@"[WizViewManager] ******* viewLoadedCallbackId : %@ ", callbackDict); 
    
    if ([callbackDict objectForKey:@"viewLoadedCallback"]) {
        NSString* callbackId = [callbackDict objectForKey:@"viewLoadedCallback"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [viewManager writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
    }
    
    if ([callbackDict objectForKey:@"updateCallback"]) {
        NSString* callbackId = [callbackDict objectForKey:@"updateCallback"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [viewManager writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
    }
    
    [callbackDict release];
    
    // Update view list array for each view
    WizViewManagerPlugin *_WizViewManagerPlugin = [WizViewManagerPlugin instance];
    [_WizViewManagerPlugin updateViewList];
    
    
    // Feed in the view name to the view's window.name property
    NSMutableDictionary *viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];
    for (NSString *key in viewList) {
        if ([[viewList objectForKey:key] isMemberOfClass:[CDVCordovaView class]]) {
            UIWebView *targetWebView = [viewList objectForKey:key];
            if ([targetWebView isEqual:theWebView]) {
                NSString *js = [NSString stringWithFormat:@"window.name = '%@'", key];
                [theWebView stringByEvaluatingJavaScriptFromString:js];
            }
        }
    }
       
}



- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSMutableURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestString = [[request URL] absoluteString];
    // get prefix
    NSArray *prefixer = [requestString componentsSeparatedByString:@":"];
    // NSLog(@"[WizWebView] ******* prefixer is:  %@", prefixer );
    
    // example request string
    // wizMessageView://mainView/{here is our data stringified}
    
    // do insensitive compare to support SDK >5
    if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"wizMessageView"] == 0) {
        
        NSArray *components = [requestString componentsSeparatedByString:@"://"];
        NSString *messageData = [[NSString alloc] initWithString:(NSString*)[components objectAtIndex:1]];
                
        NSRange range = [messageData rangeOfString:@"?"];
        
        NSString *targetView = [messageData substringToIndex:range.location];
        
        NSLog(@"[WizWebView] ******* targetView is:  %@", targetView );
        
        int targetLength = targetView.length;
        
        NSString *postData = [messageData substringFromIndex:targetLength+1];
        
        // NSLog(@"[WizWebView] ******* postData is:  %@", postData );

        NSMutableDictionary *viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];
        
        // NSLog(@"[WizWebView] ******* current views... %@", viewList);

        
        if ([viewList objectForKey:targetView]) {
            UIWebView *targetWebView = [viewList objectForKey:targetView]; 
            NSString *postDataEscaped = [postData stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
            [targetWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"wizMessageReceiver('%@');", postDataEscaped]];
            
        }

        // TODO: error handle
        // no error handle,...
        
        [messageData release];
        messageData = nil;
        [viewList release];
        
        return NO;
        
	}
    
    // Accept any other URLs
	return YES;
}

@end
