#import <objc/runtime.h>

#import "EJApp.h"
#import "EJBindingBase.h"
#import "EJCanvas/EJCanvasContext.h"
#import "EJCanvas/EJCanvasContextScreen.h"
#import "EJTimer.h"

@implementation EJApp

+ (WizCanvasView *)instance {
	return [WizCanvasView instance];
}

@end
