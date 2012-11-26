#import "EJBindingWizViewManager.h"
#import "WizViewManagerPlugin.h"

@implementation EJBindingWizViewManager


- (id)initWithContext:(JSContextRef)ctx
               object:(JSObjectRef)obj
                 argc:(size_t)argc
                 argv:(const JSValueRef [])argv
{
    if( self = [super initWithContext:ctx object:obj argc:argc argv:argv] ) {

        if( argc > 0 ) {
            // push the view's name into window
            viewName = JSValueToNSString(ctx, argv[0]);
            [[WizCanvasView instance] evaluateScript:
                          [NSString stringWithFormat:@"window.name = '%@';", viewName]];
        }
        
    }
    return self;
}


EJ_BIND_FUNCTION(message, ctx, argc, argv ) {

    if( argc < 2 ) {
        NSLog(@"Error : Not enough params supplied to wizViewMessenger.message");
        return NULL;
    }
	
	NSString *targetName = JSValueToNSString( ctx, argv[0] );
	NSString *message = JSValueToNSString( ctx, argv[1] );
	
	if( !targetName || !message ) return NULL;
    
    WizViewManagerPlugin *wizViewManager = [WizViewManagerPlugin instance];
    [wizViewManager sendMessage:targetName withMessage:message];
    return NULL;
}

@end
