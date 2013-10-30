/* WizWebView - Creates Instance of wizard UIWebView.
 *
 * @author Ally Ogilvie 
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2013
 * @file WizWebView.m for PhoneGap
 *
 */ 

#import "WizWebView.h"
#import "WizViewManagerPlugin.h"

@implementation WizWebView

@synthesize wizView;

static CDVPlugin* viewManager;

- (UIWebView *)createNewInstanceViewFromManager:(CDVPlugin *)myViewManager newBounds:(CGRect)webViewBounds sourceToLoad:(NSString *)src withOptions:(NSDictionary *)options {
    
    viewManager = myViewManager;
    
    wizView = [[UIWebView alloc] initWithFrame:webViewBounds];
    wizView.delegate = self;
    wizView.multipleTouchEnabled   = YES;
    wizView.autoresizesSubviews    = YES;
    wizView.hidden                 = NO;
    wizView.userInteractionEnabled = YES;
    wizView.opaque = NO;
    wizView.alpha = 0;
    
    // Set scales to fit setting based on Cordova settings.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Cordova" ofType:@"plist"];
    NSMutableDictionary *cordovaConfig = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if ([options objectForKey:@"scalesPageToFit"]) {
        wizView.scalesPageToFit = [[options objectForKey:@"scalesPageToFit"] boolValue];
    } else {
        NSNumber *scaleToFit = [cordovaConfig objectForKey:@"EnableViewportScale"];
        if ( scaleToFit ) {
            wizView.scalesPageToFit = [scaleToFit boolValue];
        } else {
            wizView.scalesPageToFit = NO;
            NSLog(@"[WizWebView] ******* WARNING  - EnableViewportScale was not specified in Cordova.plist");
        }
    }
    
    NSLog(@"[WizWebView] ******* building new view SOURCE IS URL? - %i", [self validateUrl:src]);

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

- (BOOL) validateUrl: (NSString *) candidate {
    NSString* lowerCased = [candidate lowercaseString];
    return [lowerCased hasPrefix:@"http://"] || [lowerCased hasPrefix:@"https://"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    NSMutableDictionary * callbackDict = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViewLoadedCallbackId]];
    
    NSLog(@"[WizViewManager] ******* viewLoadedCallbackId : %@ ", callbackDict);

    NSString *messageString = [error localizedFailureReason] ?
                                [NSString stringWithFormat:@"error - %@ : %@", [error localizedDescription], [error localizedFailureReason]] :
                                [NSString stringWithFormat:@"error - %@", [error localizedDescription]];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:messageString];
    
    if ([callbackDict objectForKey:@"viewLoadedCallback"]) {
        NSString* callbackId = [callbackDict objectForKey:@"viewLoadedCallback"];
        [viewManager writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
    }
    
    if ([callbackDict objectForKey:@"updateCallback"]) {
        NSString* callbackId = [callbackDict objectForKey:@"updateCallback"];
        [viewManager writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
	// view is loaded
    NSLog(@"[WizWebView] ******* view is LOADED! " );

    // to send data straight to mainView onLoaded via phonegap callback
     
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
        if ([[viewList objectForKey:key] isMemberOfClass:[UIWebView class]]) {
            UIWebView *targetWebView = [viewList objectForKey:key];
            if ([targetWebView isEqual:theWebView]) {
                NSString *js = [NSString stringWithFormat:@"window.name = '%@'", key];
                [theWebView stringByEvaluatingJavaScriptFromString:js];
            }
        }
    }

    // Load in wizViewMessenger
    NSString *js = @"var WizViewMessenger = function () {}; \
    WizViewMessenger.prototype.postMessage = function (message, targetView) { \
        var type; \
        if (Object.prototype.toString.call(message) === '[object Array]') { \
            type = 'Array'; \
            message = JSON.stringify(message); \
        } else if (Object.prototype.toString.call(message) === '[object String]') { \
            type = 'String'; \
        } else if (Object.prototype.toString.call(message) === '[object Number]') { \
            type = 'Number'; \
            message = JSON.stringify(message); \
        } else if (Object.prototype.toString.call(message) === '[object Boolean]') { \
            type = 'Boolean'; \
            message = message.toString(); \
        } else if (Object.prototype.toString.call(message) === '[object Function]') { \
            type = 'Function'; \
            message = message.toString(); \
        } else if (Object.prototype.toString.call(message) === '[object Object]') { \
            type = 'Object'; \
            message = JSON.stringify(message); \
        } else { \
            console.error('WizViewMessenger posted unknown type!'); \
            return; \
        } \
 \
        var iframe = document.createElement('IFRAME'); \
        iframe.setAttribute('src', 'wizPostMessage://'+ window.encodeURIComponent(window.name) + '?' + window.encodeURIComponent(targetView) + '?' + window.encodeURIComponent(message) + '?' + type ); \
        document.documentElement.appendChild(iframe); \
        iframe.parentNode.removeChild(iframe); \
        iframe = null; \
    }; \
 \
    WizViewMessenger.prototype.__triggerMessageEvent = function (origin, target, data, type) { \
        if (type === 'Array') { \
            data = JSON.parse(data); \
        } else if (type === 'String') { \
            /* Stringy String String */ \
        } else if (type === 'Number') { \
            data = JSON.parse(data); \
        } else if (type === 'Boolean') { \
            data = Boolean(data); \
        } else if (type === 'Function') { \
            /* W3C says nothing about functions, will be returned as string. */ \
        } else if (type === 'Object') { \
            data = JSON.parse(data); \
        } else { \
            console.error('Message Event received unknown type!'); \
            return; \
        } \
 \
        var event = document.createEvent('HTMLEvents'); \
        event.initEvent('message', true, true); \
        event.eventName = 'message'; \
        event.memo = { }; \
        event.origin = origin; \
        event.source = target; \
        event.data = data; \
        dispatchEvent(event); \
    }; \
 \
    window.wizViewMessenger = new WizViewMessenger(); ";
    
    [theWebView stringByEvaluatingJavaScriptFromString:js];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSMutableURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestString = [[request URL] absoluteString];
    // get prefix
    NSArray *prefixer = [requestString componentsSeparatedByString:@":"];
    // NSLog(@"[WizWebView] ******* prefixer is:  %@", prefixer );

    // do insensitive compare to support SDK >5
    if ([(NSString*)[prefixer objectAtIndex:0] caseInsensitiveCompare:@"wizPostMessage"] == 0) {
        
        NSArray *requestComponents = [requestString componentsSeparatedByString:@"://"];
        NSString *postMessage = [[NSString alloc] initWithString:(NSString*)[requestComponents objectAtIndex:1]];
        
        NSArray *messageComponents = [postMessage componentsSeparatedByString:@"?"];
        
        NSString *originView = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:0]];
        NSString *targetView = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:1]];
        NSString *data = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:2]];
        NSString *type = [[NSString alloc] initWithString:(NSString*)[messageComponents objectAtIndex:3]];
        
        NSLog(@"[WizWebView] ******* targetView is:  %@", targetView );
        
        // NSLog(@"[AppDelegate wizMessageView()] ******* postData is:  %@", postData );
        
        NSMutableDictionary *viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];
        
        if ([viewList objectForKey:targetView]) {
            NSString *postDataEscaped = [data stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
            
            UIWebView* targetWebView = [viewList objectForKey:targetView];
            NSString *js = [NSString stringWithFormat:@"wizViewMessenger.__triggerMessageEvent( window.decodeURIComponent('%@'), window.decodeURIComponent('%@'), window.decodeURIComponent('%@'), '%@' );", originView, targetView, postDataEscaped, type];
            [targetWebView stringByEvaluatingJavaScriptFromString:js];

            // WizLog(@"[AppDelegate wizMessageView()] ******* current views... %@", viewList);
        }
        
        [postMessage release];
        postMessage = nil;
        [originView release];
        [targetView release];
        [data release];
        [viewList release];
        
        return NO;
        
 	}
    
    // Accept any other URLs
	return YES;
}

@end
