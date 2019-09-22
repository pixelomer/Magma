#import "UIImage+ResizeImage.h"

@implementation UIImage(ResizeImage)

- (instancetype)resizedImageOfSize:(CGSize)size {
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
	[self drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
	UIGraphicsEndImageContext();
	return newImage;
}

@end
