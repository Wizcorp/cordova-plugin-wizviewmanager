#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class WizCanvasView;

@interface EJTimerCollection : NSObject {
	NSMutableDictionary *timers;
	int lastId;
	WizCanvasView *scriptView;
}

- (id)initWithScriptView:(WizCanvasView *)scriptView;
- (int)scheduleCallback:(JSObjectRef)callback interval:(NSTimeInterval)interval repeat:(BOOL)repeat;
- (void)cancelId:(int)timerId;
- (void)update;

@end


@interface EJTimer : NSObject {
	NSTimeInterval interval;
	JSObjectRef callback;
	BOOL active, repeat;
	WizCanvasView *scriptView;
}

- (id)initWithScriptView:(WizCanvasView *)scriptViewp
	callback:(JSObjectRef)callbackp
	interval:(NSTimeInterval)intervalp
	repeat:(BOOL)repeatp;
- (void)check;

@property (readonly) BOOL active;

@end
