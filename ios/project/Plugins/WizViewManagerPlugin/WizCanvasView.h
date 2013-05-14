/* WizWebView - Creates Instance of wizard UIWebView.
 *
 * @author WizCorp Inc. [ Incorporated Wizards ] 
 * @copyright 2011
 * @file WizWebView.h for PhoneGap
 *
 */ 

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


#import <QuartzCore/QuartzCore.h>
#import "JavaScriptCore/JavaScriptCore.h"
#import "EJConvert.h"

#define EJECTA_VERSION @"1.1"
#define EJECTA_APP_FOLDER @"www/"

#define EJECTA_BOOT_JS @"phonegap/plugin/wizViewManager/ejecta.js"
#define WIZVIEWMANAGER_BOOT_JS @"phonegap/plugin/wizViewManager/wizViewCanvasManager.js"
#define EJECTA_MAIN_JS @"index.js"

@protocol EJTouchDelegate
- (void)triggerEvent:(NSString *)name withChangedTouches:(NSSet *)changed allTouches:(NSSet *)all;
@end

@class EJTimerCollection;
@class EJCanvasContext;
@class EJCanvasContextScreen;

@interface WizCanvasView : UIViewController {
    BOOL paused;
	BOOL landscapeMode;
	JSGlobalContextRef jsGlobalContext;
	UIView * window;
	NSMutableDictionary * jsClasses;
	UIImageView * loadingScreen;
	NSObject<EJTouchDelegate> * touchDelegate;
	
	EJTimerCollection * timers;
	NSTimeInterval currentTime;
	
	EAGLContext * glContext;
	CADisplayLink * displayLink;
	
	NSOperationQueue * opQueue;
	EJCanvasContext * currentRenderingContext;
	EJCanvasContextScreen * screenRenderingContext;
	
	float internalScaling;
}

- (id)initWithWindow:(UIView *)window name:(NSString*)viewName sourceToLoad:(NSString*)src;

- (void)run:(CADisplayLink *)sender;
- (void)pause;
- (void)resume;
- (void)clearCaches;
- (NSString *)pathForResource:(NSString *)resourcePath;
- (JSValueRef)createTimer:(JSContextRef)ctx argc:(size_t)argc argv:(const JSValueRef [])argv repeat:(BOOL)repeat;
- (JSValueRef)deleteTimer:(JSContextRef)ctx argc:(size_t)argc argv:(const JSValueRef [])argv;

- (JSClassRef)getJSClassForClass:(id)classId;
- (void)hideLoadingScreen;
// Added for pure script injection wizardry - ao.
- (void)evaluateScript:(NSString *)path;
- (void)loadScriptAtPath:(NSString *)path;
- (BOOL)loadRequest:(NSString *)url;
- (JSValueRef)invokeCallback:(JSObjectRef)callback thisObject:(JSObjectRef)thisObject argc:(size_t)argc argv:(const JSValueRef [])argv;
- (void)logException:(JSValueRef)exception ctx:(JSContextRef)ctxp;


+ (WizCanvasView *)instance;


@property (nonatomic, readonly) BOOL landscapeMode;
@property (nonatomic, readonly) JSGlobalContextRef jsGlobalContext;
@property (nonatomic, readonly) EAGLContext * glContext;
@property (nonatomic, readonly) UIView * window;
@property (nonatomic, retain) NSObject<EJTouchDelegate> * touchDelegate;

@property (nonatomic, readonly) NSOperationQueue * opQueue;
@property (nonatomic, assign) EJCanvasContext * currentRenderingContext;
@property (nonatomic, assign) EJCanvasContextScreen * screenRenderingContext;
@property (nonatomic) float internalScaling;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
