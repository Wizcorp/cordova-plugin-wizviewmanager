#import "EJBindingEventedBase.h"
#import "WizCanvasView.h"

@interface EJBindingWindowEvents : EJBindingEventedBase <EJWindowEventsDelegate>

- (void)pause;
- (void)resume;
- (void)resize;

@end
