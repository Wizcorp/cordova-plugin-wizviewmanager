/* WizWKWebView - Creates Instance of wizard WKWebView.
 *
 * @author aogilvie@wizcorp.jp
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2014
 * @file WizWKWebView.m for PhoneGap
 *
 */
#import "WizDebugLog.h"
#import "WizWKWebView.h"
#import "WizViewManagerPlugin.h"

@implementation WizWKWebView

@synthesize wizView, viewName;

static CDVPlugin *viewManager;

- (NSDictionary *)throwError:(int)errorCode description:(NSString *)description {
    return @{ @"code": [NSNumber numberWithInt:errorCode], @"message": description };
}

- (WKWebView *)createNewInstanceViewFromManager:(CDVPlugin *)myViewManager newBounds:(CGRect)webViewBounds viewName:(NSString *)name sourceToLoad:(NSString *)src withOptions:(NSDictionary *)options {
    
    viewName = name;
    viewManager = myViewManager;
    
    wizView = [[WKWebView alloc] initWithFrame:webViewBounds];
    wizView.UIDelegate = self;
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
        // wizView.scalesPageToFit = [[options objectForKey:@"scalesPageToFit"] boolValue];
    } else {
        NSNumber *scaleToFit = [cordovaConfig objectForKey:@"EnableViewportScale"];
        if (scaleToFit) {
            // wizView.scalesPageToFit = [scaleToFit boolValue];
        } else {
            // wizView.scalesPageToFit = NO;
            NSLog(@"[WizWebView] ******* WARNING  - EnableViewportScale was not specified in Cordova.plist");
        }
    }

    // Set bounces setting based on option settings.
    if ([options objectForKey:@"bounces"]) {
        wizView.scrollView.bounces = [[options objectForKey:@"bounces"] boolValue];
    } else {
        wizView.scrollView.bounces = NO;
    }

    wizView.bounds = webViewBounds;

    [wizView setFrame:CGRectMake(
            webViewBounds.origin.x,
            webViewBounds.origin.y,
            webViewBounds.size.width,
            webViewBounds.size.height
    )];

    WizLog(@"[WizWebView] ******* building new view SOURCE IS URL? - %i", [self validateUrl:src]);

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
        // Not a URL, a local resource, check file extension
        WizViewManagerPlugin *wizViewManagerPlugin = [WizViewManagerPlugin instance];
        if (![wizViewManagerPlugin validateFileExtension:src]) {
            NSLog(@"Invalid extension type!");
            return NULL;
        }

        NSURL *url;
        // Is relative path? Try to load from cache
        NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [pathList  objectAtIndex:0];
        // Better to use initFileURLWithPath:isDirectory: if you know if the path is a directory vs non-directory, as it saves an i/o
        url = [[NSURL alloc] initFileURLWithPath:src isDirectory:NO];
        NSString *cacheSrc = [NSString stringWithFormat:@"%@/%@", cachePath, src];
        WizLog(@"check: %@", cacheSrc);
        if ([url.absoluteString isKindOfClass:[NSNull class]] || ![[NSFileManager defaultManager] fileExistsAtPath:cacheSrc]) {
            // Not in cache, try main bundle
            url = [[NSURL alloc] initFileURLWithPath:src isDirectory:NO];
            NSString *bundleSrc = [NSString stringWithFormat:@"%@/www/%@", [NSBundle mainBundle].bundlePath, src];
            WizLog(@"check: %@", bundleSrc);
            if ([url.absoluteString isKindOfClass:[NSNull class]] || ![[NSFileManager defaultManager] fileExistsAtPath:bundleSrc]) {
                // Not in main bundle, try full path
                WizLog(@"check: %@", src);
                if ([[NSFileManager defaultManager] fileExistsAtPath:src]) {
                    // Valid full path source, load it
                    url = [[NSURL alloc] initFileURLWithPath:src];
                    WizLog(@"Full path url as string %@", url.absoluteString);
                    /*
                     [wizView loadRequest:[NSURLRequest requestWithURL:url]];
                     */
                    // Load from temp
                    [self copy:src andLoad:src];
                } else {
                    NSLog(@"Load Error: invalid source");
                    if (![wizViewManagerPlugin validateFileExtension:src]) {
                        NSLog(@"Load Error: No or NULL source");
                        return NULL;
                    }
                }
            } else {
                url = [[NSURL alloc] initFileURLWithPath:bundleSrc];
                WizLog(@"Relative url in bundle %@", url.absoluteString);
                /*
                [wizView loadRequest:[NSURLRequest requestWithURL:url]];
                 */
                // Load from temp
                [self copy:bundleSrc andLoad:src];
            }
        } else {
            url = [[NSURL alloc] initFileURLWithPath:cacheSrc];
            WizLog(@"Relative url in cache %@", url.absoluteString);
            /*
             [wizView loadRequest:[NSURLRequest requestWithURL:url]];
             */
            // Load from temp
            [self copy:cacheSrc andLoad:src];
        }
    }

    wizView.UIDelegate = self;
    wizView.navigationDelegate = self;

    // add this view as subview after creating instance in parent class.
    return wizView;
}

// THIS FUNCTION WILL BE REMOVED WHEN WKWEBVIEW SUPPORTS FILE LOADING FROM OUTSIDE OF /tmp
- (void)copy:(NSString *)fullPath andLoad:(NSString *)src {
    // Does file already exist at tmp?
    NSError *copyError = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src]]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src] error:&copyError]) {
            NSLog(@"Error deleting file: %@", [copyError localizedDescription]);
        }
    }

    // Copy to tmp
    if (![[NSFileManager defaultManager] copyItemAtPath:fullPath toPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src] error:&copyError]) {
        NSLog(@"Error copying file: %@", [copyError localizedDescription]);
        return;
    }
    // Load from tmp
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src]];
    [wizView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (BOOL)validateUrl:(NSString *)candidate {
    NSString *lowerCased = [candidate lowercaseString];
    return [lowerCased hasPrefix:@"http://"] || [lowerCased hasPrefix:@"https://"];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {

    if (error.code == -999) {
        // Ignore this code. It's thrown when the UIWebView is asked to load new content before finishing to load previous request
        return;
    }
    NSMutableDictionary *callbackDict = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViewLoadedCallbackId]];
    
    WizLog(@"[WizViewManager] ******* didFailLoadWithError Code : %i Description : %@ Failure : %@", error.code, error.localizedDescription, error.localizedFailureReason);
    
    CDVPluginResult *pluginResult;
    if ([callbackDict objectForKey:[NSString stringWithFormat:@"%@_viewLoadedCallback", viewName]]) {
        NSString *callbackId = [callbackDict objectForKey:[NSString stringWithFormat:@"%@_viewLoadedCallback", viewName]];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[self throwError:203 description:@"Loading source error"]];
        [viewManager writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
        // Remove callback
        [WizViewManagerPlugin removeViewLoadedCallback:[NSString stringWithFormat:@"%@_viewLoadedCallback", viewName]];
    }
    
    if ([callbackDict objectForKey:[NSString stringWithFormat:@"%@_updateCallback", viewName]]) {
        NSString *callbackId = [callbackDict objectForKey:[NSString stringWithFormat:@"%@_updateCallback", viewName]];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[self throwError:103 description:@"Loading source error"]];
        [viewManager writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
        // Remove callback
        [WizViewManagerPlugin removeViewLoadedCallback:[NSString stringWithFormat:@"%@_updateCallback", viewName]];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	// view is loaded
    WizLog(@"[WizWebView] ******* webViewDidFinishLoad" );

    // to send data straight to mainView onLoaded via phonegap callback
     
    NSMutableDictionary *callbackDict = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViewLoadedCallbackId]];
    
    WizLog(@"[WizViewManager] ******* viewName: %@ viewLoadedCallbackId : %@ ", callbackDict, viewName);
    
    if ([callbackDict objectForKey:[NSString stringWithFormat:@"%@_viewLoadedCallback", viewName]]) {
        NSString *callbackId = [callbackDict objectForKey:[NSString stringWithFormat:@"%@_viewLoadedCallback", viewName]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [viewManager writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
        // Remove callback
        [WizViewManagerPlugin removeViewLoadedCallback:[NSString stringWithFormat:@"%@_viewLoadedCallback", viewName]];
    }
    
    if ([callbackDict objectForKey:[NSString stringWithFormat:@"%@_updateCallback", viewName]]) {
        NSString *callbackId = [callbackDict objectForKey:[NSString stringWithFormat:@"%@_updateCallback", viewName]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [viewManager writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
        // Remove callback
        [WizViewManagerPlugin removeViewLoadedCallback:[NSString stringWithFormat:@"%@_updateCallback", viewName]];
    }

    // Update view list array for each view
    WizViewManagerPlugin *wizViewManagerPlugin = [WizViewManagerPlugin instance];
    [wizViewManagerPlugin updateViewList];
    
    
    // Feed in the view name to the view's window.name property
    NSMutableDictionary *viewList = [[NSMutableDictionary alloc] initWithDictionary:[WizViewManagerPlugin getViews]];
    for (NSString *key in viewList) {
        if ([[viewList objectForKey:key] isMemberOfClass:[UIWebView class]]) {
            WKWebView *targetWebView = [viewList objectForKey:key];
            if ([targetWebView isEqual:webView]) {
                NSString *js = [NSString stringWithFormat:@"window.name = '%@'", key];
                [webView evaluateJavaScript:js completionHandler:NULL];
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
        origin = decodeURIComponent(origin); \
        target = decodeURIComponent(target); \
        data = decodeURIComponent(data); \
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
    
    [webView evaluateJavaScript:js completionHandler:NULL];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSString *requestString = [[navigationAction.request URL] absoluteString];
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
            NSString *js = [NSString stringWithFormat:@"wizViewMessenger.__triggerMessageEvent(\"%@\", \"%@\", \"%@\", \"%@\");", originView, targetView, data, type];

            if ([targetView isEqualToString:@"mainView"]) {
                UIWebView *targetWebView = [viewList objectForKey:targetView];
                [targetWebView stringByEvaluatingJavaScriptFromString:js];
            } else {
                WKWebView *targetWebView = [viewList objectForKey:targetView];
                [targetWebView evaluateJavaScript:js completionHandler:NULL];
            }
            // WizLog(@"[AppDelegate wizMessageView()] ******* current views... %@", viewList);
        }
        postMessage = nil;
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    // Accept any other URLs
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
