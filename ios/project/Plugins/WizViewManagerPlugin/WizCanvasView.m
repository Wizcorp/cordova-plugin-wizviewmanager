/* WizCanvasView - Setup and deploy an Ejecta canvas.
 *
 * @author Ally Ogilvie 
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2012
 * @file WizCanvasView.m for PhoneGap
 *
 */ 

#import "WizCanvasView.h"
#import "EJTimer.h"
#import "EJBindingBase.h"
#import "EJClassLoader.h"
#import "EJBindingTouchInput.h"
#import <objc/runtime.h>


// Block function callbacks
JSValueRef EJBlockFunctionCallAsFunction(
        JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argc, const JSValueRef argv[], JSValueRef* exception
) {
    JSValueRef (^block)(JSContextRef ctx, size_t argc, const JSValueRef argv[]) = JSObjectGetPrivate(function);
    JSValueRef ret = block(ctx, argc, argv);
    return ret ? ret : JSValueMakeUndefined(ctx);
}

void EJBlockFunctionFinalize(JSObjectRef object) {
    JSValueRef (^block)(JSContextRef ctx, size_t argc, const JSValueRef argv[]) = JSObjectGetPrivate(object);
    [block release];
}

#pragma mark -
#pragma mark Ejecta view Implementation

@implementation WizCanvasView

@synthesize appFolder;

@synthesize pauseOnEnterBackground;
@synthesize isPaused;
@synthesize hasScreenCanvas;
@synthesize jsGlobalContext;

@synthesize currentRenderingContext;
@synthesize openGLContext;

@synthesize windowEventsDelegate;
@synthesize touchDelegate;
@synthesize deviceMotionDelegate;
@synthesize screenRenderingContext;

@synthesize backgroundQueue;
@synthesize classLoader;

static WizCanvasView * ejectaInstance = NULL;


+ (WizCanvasView *)instance {
	return ejectaInstance;
}

- (id)initWithWindow:(UIView *)windowp name:(NSString*)viewName sourceToLoad:(NSString*)src {
	if( self = [super init] ) {
        NSLog(@"frame of canvas window: %f", [windowp bounds].size.height);

        landscapeMode = [[[NSBundle mainBundle] infoDictionary][@"UIInterfaceOrientation"]
                hasPrefix:@"UIInterfaceOrientationLandscape"];

        oldSize = [windowp bounds].size;
        appFolder = EJECTA_APP_FOLDER;

        isPaused = false;

        // CADisplayLink (and NSNotificationCenter?) retains it's target, but this
        // is causing a retain loop - we can't completely release the scriptView
        // from the outside.
        // So we're using a "weak proxy" that doesn't retain the scriptView; we can
        // then just invalidate the CADisplayLink in our dealloc and be done with it.
        proxy = [[EJNonRetainingProxy proxyWithTarget:self] retain];

        self.pauseOnEnterBackground = YES;

        // Limit all background operations (image & sound loading) to one thread
        backgroundQueue = [[NSOperationQueue alloc] init];
        backgroundQueue.maxConcurrentOperationCount = 1;

        timers = [[EJTimerCollection alloc] initWithScriptView:self];

        displayLink = [[CADisplayLink displayLinkWithTarget:proxy selector:@selector(run:)] retain];
        [displayLink setFrameInterval:1];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        // Create the global JS context in its own group, so it can be released properly
        jsGlobalContext = JSGlobalContextCreateInGroup(NULL, NULL);
        jsUndefined = JSValueMakeUndefined(jsGlobalContext);
        JSValueProtect(jsGlobalContext, jsUndefined);

        // Attach all native class constructors to 'Ejecta'
        classLoader = [[EJClassLoader alloc] initWithScriptView:self name:@"Ejecta"];


        // Retain the caches here, so even if they're currently unused in JavaScript,
        // they will persist until the last scriptView is released
        textureCache = [[EJSharedTextureCache instance] retain];
        openALManager = [[EJSharedOpenALManager instance] retain];
        openGLContext = [[EJSharedOpenGLContext instance] retain];

        // Create the OpenGL context for Canvas2D
        glCurrentContext = openGLContext.glContext2D;
        [EAGLContext setCurrentContext:glCurrentContext];


		ejectaInstance = self;
		window = windowp;
        self.view = window;

        // [self.window makeKeyAndVisible];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
		

        // Register for application lifecycle notifications
        
        // Register the instance to observe willResignActive notifications
/*
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pauseNotification:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];

        // Register the instance to observe didEnterBackground notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pauseNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        // Register the instance to observe didEnterForeground notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resumeNotification:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        // Register the instance to observe didBecomeActive notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resumeNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

        // Register the instance to observe willTerminate notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pauseNotification:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        // Register the instance to observe didReceiveMemoryWarning notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearCachesNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
*/
        // Load the initial JavaScript source files
	    [self loadScriptAtPath:EJECTA_BOOT_JS];
        
        // Load wizViewManager JS plugin
	    // [self loadScriptAtPath:WIZVIEWMANAGER_BOOT_JS];
        
        // Push ViewManager to Window
        // [self evaluateScript:[NSString stringWithFormat:@"window.wizViewManager = new Ejecta.WizViewManager('%@');", viewName]];
        
        // Additional boot file
        if (![src isEqualToString:@""]) {
            [self loadScriptAtPath:src];
        }
        
	}
	return self;
}

- (void)dealloc {
    // Wait until all background operations are finished. If we would just release the
    // backgroundQueue it would cancel running operations (such as texture loading) and
    // could keep some dependencies dangling
    [backgroundQueue waitUntilAllOperationsAreFinished];
    [backgroundQueue release];

    // Careful, order is important! The JS context has to be released first; it will release
    // the canvas objects which still need the openGLContext to be present, to release
    // textures etc.
    // Set 'jsGlobalContext' to null before releasing it, because it may be referenced by
    // bound objects' dealloc method
    JSValueUnprotect(jsGlobalContext, jsUndefined);
    JSGlobalContextRef ctxref = jsGlobalContext;
    jsGlobalContext = NULL;
    JSGlobalContextRelease(ctxref);

    // Remove from notification center
    self.pauseOnEnterBackground = false;

    // Remove from display link
    [displayLink invalidate];
    [displayLink release];

    [textureCache release];
    [openALManager release];
    [classLoader release];

    if( jsBlockFunctionClass ) {
        JSClassRelease(jsBlockFunctionClass);
    }
    [screenRenderingContext finish];
    [screenRenderingContext release];
    [currentRenderingContext release];

    [touchDelegate release];
    [windowEventsDelegate release];
    [deviceMotionDelegate release];

    [timers release];

    [openGLContext release];
    [appFolder release];
    [super dealloc];
}

- (void)setPauseOnEnterBackground:(BOOL)pauses {
    NSArray *pauseN = @[
            UIApplicationWillResignActiveNotification,
            UIApplicationDidEnterBackgroundNotification,
            UIApplicationWillTerminateNotification
    ];
    NSArray *resumeN = @[
            UIApplicationWillEnterForegroundNotification,
            UIApplicationDidBecomeActiveNotification
    ];

    if (pauses) {
        [self observeKeyPaths:pauseN selector:@selector(pause)];
        [self observeKeyPaths:resumeN selector:@selector(resume)];
    }
    else {
        [self removeObserverForKeyPaths:pauseN];
        [self removeObserverForKeyPaths:resumeN];
    }
    pauseOnEnterBackground = pauses;
}

- (void)removeObserverForKeyPaths:(NSArray*)keyPaths {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    for( NSString *name in keyPaths ) {
        [nc removeObserver:proxy name:name object:nil];
    }
}

- (void)observeKeyPaths:(NSArray*)keyPaths selector:(SEL)selector {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    for( NSString *name in keyPaths ) {
        [nc addObserver:proxy selector:selector name:name object:nil];
    }
}

- (void)layoutSubviews {

    // [super layoutSubviews];

    // Check if we did resize
    CGSize newSize = self.view.bounds.size;
    if( newSize.width != oldSize.width || newSize.height != oldSize.height ) {
        [windowEventsDelegate resize];
        oldSize = newSize;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    if (landscapeMode) {
        // Allow Landscape Left and Right
        return UIInterfaceOrientationMaskLandscape;
    }
    else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
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
    return (self.supportedInterfaceOrientations & (1 << orientation));
}


#pragma mark -
#pragma mark Run loop

- (void)run:(CADisplayLink *)sender {
    if(isPaused) { return; }

    // We rather poll for device motion updates at the beginning of each frame instead of
    // spamming out updates that will never be seen.
    [deviceMotionDelegate triggerDeviceMotionEvents];

    // Check all timers
    [timers update];

    // Redraw the canvas
    self.currentRenderingContext = screenRenderingContext;
    [screenRenderingContext present];
}


- (void)pause {
    if( isPaused ) { return; }

    [windowEventsDelegate pause];
    [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [screenRenderingContext finish];
    isPaused = true;
}

- (void)resume {
    if( !isPaused ) { return; }

    [windowEventsDelegate resume];
    [EAGLContext setCurrentContext:glCurrentContext];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    isPaused = false;
}

- (void)clearCaches {
    JSGarbageCollect(jsGlobalContext);
}

- (void)setCurrentRenderingContext:(EJCanvasContext *)renderingContext {
    if( renderingContext != currentRenderingContext ) {
        [currentRenderingContext flushBuffers];
        [currentRenderingContext release];

        // Switch GL Context if different
        if( renderingContext && renderingContext.glContext != glCurrentContext ) {
            glFlush();
            glCurrentContext = renderingContext.glContext;
            [EAGLContext setCurrentContext:glCurrentContext];
        }

        [renderingContext prepare];
        currentRenderingContext = [renderingContext retain];
    }
}

- (void)hideLoadingScreen {
	//[loadingScreen removeFromSuperview];
	//[loadingScreen release];
	//loadingScreen = nil;
}

- (NSString *)pathForResource:(NSString *)path {
	return [NSString stringWithFormat:@"%@/" EJECTA_APP_FOLDER "%@", [[NSBundle mainBundle] resourcePath], path];
}

#pragma mark -
#pragma mark Script loading and execution

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

- (JSValueRef)loadModuleWithId:(NSString *)moduleId module:(JSValueRef)module exports:(JSValueRef)exports {
    NSString *path = [moduleId stringByAppendingString:@".js"];
    NSString *script = [NSString stringWithContentsOfFile:[self pathForResource:path]
                                                 encoding:NSUTF8StringEncoding error:NULL];

    if( !script ) {
        NSLog(@"Error: Can't Find Module %@", moduleId );
        return NULL;
    }

    NSLog(@"Loading Module: %@", moduleId );

    JSStringRef scriptJS = JSStringCreateWithCFString((CFStringRef)script);
    JSStringRef pathJS = JSStringCreateWithCFString((CFStringRef)path);
    JSStringRef parameterNames[] = {
            JSStringCreateWithUTF8CString("module"),
            JSStringCreateWithUTF8CString("exports"),
    };

    JSValueRef exception = NULL;
    JSObjectRef func = JSObjectMakeFunction(jsGlobalContext, NULL, 2, parameterNames, scriptJS, pathJS, 0, &exception );

    JSStringRelease( scriptJS );
    JSStringRelease( pathJS );
    JSStringRelease(parameterNames[0]);
    JSStringRelease(parameterNames[1]);

    if( exception ) {
        [self logException:exception ctx:jsGlobalContext];
        return NULL;
    }

    JSValueRef params[] = { module, exports };
    return [self invokeCallback:func thisObject:NULL argc:2 argv:params];
}

- (JSValueRef)invokeCallback:(JSObjectRef)callback thisObject:(JSObjectRef)thisObject argc:(size_t)argc argv:(const JSValueRef [])argv {
    if( !jsGlobalContext ) { return NULL; } // May already have been released

    JSValueRef exception = NULL;
    JSValueRef result = JSObjectCallAsFunction(jsGlobalContext, callback, thisObject, argc, argv, &exception );
    [self logException:exception ctx:jsGlobalContext];
    return result;
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



#pragma mark -
#pragma mark Touch handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [touchDelegate triggerEvent:@"touchstart" all:event.allTouches changed:touches remaining:event.allTouches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSMutableSet *remaining = [event.allTouches mutableCopy];
    [remaining minusSet:touches];

    [touchDelegate triggerEvent:@"touchend" all:event.allTouches changed:touches remaining:remaining];
    [remaining release];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [touchDelegate triggerEvent:@"touchmove" all:event.allTouches changed:touches remaining:event.allTouches];
}


#pragma mark
#pragma mark Timers

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

- (JSObjectRef)createFunctionWithBlock:(JSValueRef (^)(JSContextRef ctx, size_t argc, const JSValueRef argv[]))block {
    if( !jsBlockFunctionClass ) {
        JSClassDefinition blockFunctionClassDef = kJSClassDefinitionEmpty;
        blockFunctionClassDef.callAsFunction = EJBlockFunctionCallAsFunction;
        blockFunctionClassDef.finalize = EJBlockFunctionFinalize;
        jsBlockFunctionClass = JSClassCreate(&blockFunctionClassDef);
    }

    return JSObjectMake( jsGlobalContext, jsBlockFunctionClass, (void *)Block_copy(block) );
}

@end
