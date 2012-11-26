/* WizCanvasView - Setup and deploy an Ejecta canvas.
 *
 * @author Ally Ogilvie 
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2012
 * @file WizCanvasView.m for PhoneGap
 *
 */ 

#import "WizCanvasView.h"
#import "WizViewManagerPlugin.h"


#import <objc/runtime.h>

#import "Ejecta/EJBindingBase.h"
#import "Ejecta/EJCanvas/EJCanvasContext.h"
#import "Ejecta/EJCanvas/EJCanvasContextScreen.h"
#import "Ejecta/EJTimer.h"




// ---------------------------------------------------------------------------------
// JavaScript callback functions to retrieve and create instances of a native class

JSValueRef ej_global_undefined;
JSClassRef ej_constructorClass;
JSValueRef ej_getNativeClass(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception) {
	CFStringRef className = JSStringCopyCFString( kCFAllocatorDefault, propertyNameJS );
	
	JSObjectRef obj = NULL;
	NSString * fullClassName = [NSString stringWithFormat:@"EJBinding%@", className];
	id class = NSClassFromString(fullClassName);
	if( class ) {
		obj = JSObjectMake( ctx, ej_constructorClass, (void *)class );
	}
	
	CFRelease(className);
	return obj ? obj : ej_global_undefined;
}

JSObjectRef ej_callAsConstructor(JSContextRef ctx, JSObjectRef constructor, size_t argc, const JSValueRef argv[], JSValueRef* exception) {
	id class = (id)JSObjectGetPrivate( constructor );
	
	JSClassRef jsClass = [[WizCanvasView instance] getJSClassForClass:class];
	JSObjectRef obj = JSObjectMake( ctx, jsClass, NULL );
	
	id instance = [(EJBindingBase *)[class alloc] initWithContext:ctx object:obj argc:argc argv:argv];
	JSObjectSetPrivate( obj, (void *)instance );
	
	return obj;
}




// ---------------------------------------------------------------------------------
// Ejecta Main Class implementation - this creates the JavaScript Context and loads
// the initial JavaScript source files
@implementation WizCanvasView

@synthesize landscapeMode;
@synthesize jsGlobalContext;
@synthesize window;
@synthesize touchDelegate;

@synthesize opQueue;
@synthesize currentRenderingContext;
@synthesize screenRenderingContext;
@synthesize internalScaling;

static WizCanvasView * ejectaInstance = NULL;


+ (WizCanvasView *)instance {
	return ejectaInstance;
}

- (id)initWithWindow:(UIView *)windowp name:(NSString*)viewName sourceToLoad:(NSString*)src {
	if( self = [super init] ) {
		
		landscapeMode = [[[[NSBundle mainBundle] infoDictionary]
                          objectForKey:@"UIInterfaceOrientation"] hasPrefix:@"UIInterfaceOrientationLandscape"];
		
        
		ejectaInstance = self;
		window = windowp;
        self.view = window;
        
        UITapGestureRecognizer *touchRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget: self
                                                action: @selector(handleTouch:)];
        touchRecognizer.numberOfTapsRequired = 1;
        touchRecognizer.numberOfTouchesRequired = 1;
        
        [self.window addGestureRecognizer:touchRecognizer];
        // [self.window makeKeyAndVisible];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
		
		
		// Show the loading screen - commented out for now.
		// This causes some visual quirks on different devices, as the launch screen may be a
		// different one than we loade here - let's rather show a black screen for 200ms...
		//NSString * loadingScreenName = [EJApp landscapeMode] ? @"Default-Landscape.png" : @"Default-Portrait.png";
		//loadingScreen = [[UIImageView alloc] initWithImage:[UIImage imageNamed:loadingScreenName]];
		//loadingScreen.frame = self.view.bounds;
		//[self.view addSubview:loadingScreen];
		
		paused = false;
		internalScaling = 1;
		
		// Limit all background operations (image & sound loading) to one thread
		opQueue = [[NSOperationQueue alloc] init];
		opQueue.maxConcurrentOperationCount = 1;
		
		timers = [[EJTimerCollection alloc] init];
		
		displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(run:)] retain];
		[displayLink setFrameInterval:1];
		[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		
        
		// Create the global JS context and attach the 'Ejecta' object
		jsClasses = [[NSMutableDictionary alloc] init];
        
		JSClassDefinition constructorClassDef = kJSClassDefinitionEmpty;
		constructorClassDef.callAsConstructor = ej_callAsConstructor;
		ej_constructorClass = JSClassCreate(&constructorClassDef);
		
		JSClassDefinition globalClassDef = kJSClassDefinitionEmpty;
		globalClassDef.getProperty = ej_getNativeClass;
		JSClassRef globalClass = JSClassCreate(&globalClassDef);
        
        
		jsGlobalContext = JSGlobalContextCreate(NULL);
		ej_global_undefined = JSValueMakeUndefined(jsGlobalContext);
		JSValueProtect(jsGlobalContext, ej_global_undefined);
		JSObjectRef globalObject = JSContextGetGlobalObject(jsGlobalContext);
		
		JSObjectRef iosObject = JSObjectMake( jsGlobalContext, globalClass, NULL );
		JSObjectSetProperty(
                            jsGlobalContext, globalObject,
                            JSStringCreateWithUTF8CString("Ejecta"), iosObject,
                            kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly, NULL
                            );
        
		// Load the initial JavaScript source files
	    [self loadScriptAtPath:EJECTA_BOOT_JS];
        
        // Load wizViewManager JS plugin
	    [self loadScriptAtPath:WIZVIEWMANAGER_BOOT_JS];
        
        // Push ViewManager to Window
        [self evaluateScript:[NSString stringWithFormat:@"window.wizViewManager = new Ejecta.WizViewManager('%@');", viewName]];
        
        // Additional boot file
        if (![src isEqualToString:@""]) {
            [self loadScriptAtPath:src];
        }
        // self loadScriptAtPath:EJECTA_MAIN_JS];
        
	}
	return self;
}

- (void)dealloc {
	JSGlobalContextRelease(jsGlobalContext);
	[currentRenderingContext release];
	[touchDelegate release];
	[jsClasses release];
	[opQueue release];
	
	[displayLink release];
	[timers release];
	[super dealloc];
}


-(NSUInteger)supportedInterfaceOrientations {
	if( landscapeMode ) {
		// Allow Landscape Left and Right
		return UIInterfaceOrientationMaskLandscape;
	}
	else {
		if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
			// Allow Portrait UpsideDown on iPad
			return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
		}
		else {
			// Only Allow Portrait
			return UIInterfaceOrientationMaskPortrait;
		}
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	// Deprecated in iOS6 - supportedInterfaceOrientations is the new way to do this
	// We just use the mask returned by supportedInterfaceOrientations here to check if
	// this particular orientation is allowed.
	return (self.supportedInterfaceOrientations & (1 << orientation) );
}


// ---------------------------------------------------------------------------------
// The run loop

- (void)run:(CADisplayLink *)sender {
	if( paused ) { return; }
    
	// Check all timers
	[timers update];
	
	// Redraw the canvas
	self.currentRenderingContext = screenRenderingContext;
	[screenRenderingContext present];
}


- (void)pause {
	[displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[screenRenderingContext finish];
	paused = true;
}


- (void)resume {
	[screenRenderingContext resetGLContext];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	paused = false;
}


- (void)clearCaches {
	JSGarbageCollect(jsGlobalContext);
}


- (void)hideLoadingScreen {
	//[loadingScreen removeFromSuperview];
	//[loadingScreen release];
	//loadingScreen = nil;
}

- (NSString *)pathForResource:(NSString *)path {
	return [NSString stringWithFormat:@"%@/" EJECTA_APP_FOLDER "%@", [[NSBundle mainBundle] resourcePath], path];
}

// ---------------------------------------------------------------------------------
// Script loading and execution
- (void)evaluateScript:(NSString *)script {

	if( !script ) {
		NSLog(@"[evaluateScript] Error: Can't Find Script" );
		return;
	}
	
	// NSLog(@"Loading Script: %@", script );
	
    JSStringRef scriptJS = JSStringCreateWithCFString((CFStringRef)script);
	JSStringRef pathJS = JSStringCreateWithCFString((CFStringRef)@"");
	
	JSValueRef exception = NULL;
	JSEvaluateScript( jsGlobalContext, scriptJS, NULL, pathJS, 0, &exception );
	[self logException:exception ctx:jsGlobalContext];
    
	JSStringRelease( scriptJS );
}

- (void)loadScriptAtPath:(NSString *)path {
	NSString * script = [NSString stringWithContentsOfFile:[self pathForResource:path] encoding:NSUTF8StringEncoding error:NULL];

	if( !script ) {
		NSLog(@"[loadScriptAtPath] Error: Can't Find Script %@", path );
		return;
	}
	
	NSLog(@"Loading Script: %@", path );
	JSStringRef scriptJS = JSStringCreateWithCFString((CFStringRef)script);
	JSStringRef pathJS = JSStringCreateWithCFString((CFStringRef)path);

	JSValueRef exception = NULL;
	JSEvaluateScript( jsGlobalContext, scriptJS, NULL, pathJS, 0, &exception );
	[self logException:exception ctx:jsGlobalContext];
    
	JSStringRelease( scriptJS );
}

- (JSValueRef)invokeCallback:(JSObjectRef)callback thisObject:(JSObjectRef)thisObject argc:(size_t)argc argv:(const JSValueRef [])argv {
	JSValueRef exception = NULL;
	JSValueRef result = JSObjectCallAsFunction( jsGlobalContext, callback, thisObject, argc, argv, &exception );
	[self logException:exception ctx:jsGlobalContext];
	return result;
}

- (JSClassRef)getJSClassForClass:(id)classId {
	JSClassRef jsClass = [[jsClasses objectForKey:classId] pointerValue];
	// Not already loaded? Ask the objc class for the JSClassRef!
	if( !jsClass ) {
		jsClass = [classId getJSClass];
		[jsClasses setObject:[NSValue valueWithPointer:jsClass] forKey:classId];
	}
	return jsClass;
}

- (void)logException:(JSValueRef)exception ctx:(JSContextRef)ctxp {
	if( !exception ) return;
	
	JSStringRef jsLinePropertyName = JSStringCreateWithUTF8CString("line");
	JSStringRef jsFilePropertyName = JSStringCreateWithUTF8CString("sourceURL");
	
	JSObjectRef exObject = JSValueToObject( ctxp, exception, NULL );
	JSValueRef line = JSObjectGetProperty( ctxp, exObject, jsLinePropertyName, NULL );
	JSValueRef file = JSObjectGetProperty( ctxp, exObject, jsFilePropertyName, NULL );
	
	NSLog(
          @"%@ at line %@ in %@",
          JSValueToNSString( ctxp, exception ),
          JSValueToNSString( ctxp, line ),
          JSValueToNSString( ctxp, file )
          );
	
	JSStringRelease( jsLinePropertyName );
	JSStringRelease( jsFilePropertyName );
}



// ---------------------------------------------------------------------------------
// Touch handlers

// HACK to get out of viewController
- (void)handleTouch:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        //touchesBegan
        [self touchesBegan:Nil withEvent:NULL];
    } else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        //touchesEnded
        [self touchesEnded:Nil withEvent:NULL];
    } else if (recognizer.state == UIGestureRecognizerStateCancelled)
    {
        //touchesCancelled
        [self touchesCancelled:Nil withEvent:NULL];
    } else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        //touchesMoved
        // [self touchesCancelled:Nil withEvent:NULL];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"wizCanvas view TouchesBegan! ");
	[touchDelegate triggerEvent:@"touchstart" withTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchDelegate triggerEvent:@"touchend" withTouches:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchDelegate triggerEvent:@"touchend" withTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchDelegate triggerEvent:@"touchmove" withTouches:touches];
}


// ---------------------------------------------------------------------------------
// Timers

- (JSValueRef)createTimer:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv repeat:(BOOL)repeat {
	if( argc != 2 || !JSValueIsObject(ctxp, argv[0]) || !JSValueIsNumber(jsGlobalContext, argv[1]) ) {
		return NULL;
	}
	
	JSObjectRef func = JSValueToObject(ctxp, argv[0], NULL);
	float interval = JSValueToNumberFast(ctxp, argv[1])/1000;
	
	// Make sure short intervals (< 18ms) run each frame
	if( interval < 0.018 ) {
		interval = 0;
	}
	
	int timerId = [timers scheduleCallback:func interval:interval repeat:repeat];
	return JSValueMakeNumber( ctxp, timerId );
}

- (JSValueRef)deleteTimer:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( argc != 1 || !JSValueIsNumber(ctxp, argv[0]) ) return NULL;
	
	[timers cancelId:JSValueToNumberFast(ctxp, argv[0])];
	return NULL;
}

- (void)setCurrentRenderingContext:(EJCanvasContext *)renderingContext {
	if( renderingContext != currentRenderingContext ) {
		[currentRenderingContext flushBuffers];
		[currentRenderingContext release];
		[renderingContext prepare];
		currentRenderingContext = [renderingContext retain];
	}
}


@end
