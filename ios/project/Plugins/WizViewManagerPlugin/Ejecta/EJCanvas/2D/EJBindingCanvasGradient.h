#import "EJBindingBase.h"
#import "EJCanvasGradient.h"

@interface EJBindingCanvasGradient : EJBindingBase {
	EJCanvasGradient *gradient;
}

+ (JSObjectRef)createJSObjectWithContext:(JSContextRef)ctx
	scriptView:(WizCanvasView *)scriptView
	gradient:(EJCanvasGradient *)gradient;
+ (EJCanvasGradient *)gradientFromJSValue:(JSValueRef)value;

@end
