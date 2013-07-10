#import "EJCanvasContext.h"
#import "EAGLView.h"
#import "EJPresentable.h"

@class WizCanvasView;
@interface EJCanvasContextWebGL : EJCanvasContext <EJPresentable> {
	GLuint viewFrameBuffer, viewRenderBuffer;
	GLuint depthRenderBuffer;
	
	GLuint boundFramebuffer;
	GLuint boundRenderbuffer;
	
	GLint bufferWidth, bufferHeight;
	EAGLView *glview;
	WizCanvasView *scriptView;
	
	float backingStoreRatio;
	BOOL useRetinaResolution;
	
	CGRect style;
}

- (id)initWithScriptView:(WizCanvasView *)scriptView width:(short)width height:(short)height style:(CGRect)style;
- (void)bindRenderbuffer;
- (void)bindFramebuffer;
- (void)present;
- (void)finish;
- (void)create;
- (void)prepare;

@property (nonatomic) CGRect style;

@property (nonatomic) BOOL needsPresenting;
@property (nonatomic) BOOL useRetinaResolution;
@property (nonatomic,readonly) float backingStoreRatio;

@property (nonatomic) GLuint boundFramebuffer;
@property (nonatomic) GLuint boundRenderbuffer;

@end
