#import "EJBindingEventedBase.h"
#import "EJTexture.h"
#import "EJDrawable.h"

@interface EJBindingImage : EJBindingEventedBase <EJDrawable> {
	EJTexture * texture;
	NSString * path;
	BOOL loading;
}

@property (readonly, nonatomic) EJTexture * texture;

@end
