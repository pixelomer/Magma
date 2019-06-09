#import <Foundation/Foundation.h>

@interface Database : NSObject {
	BOOL _isLoaded;
}
+ (instancetype)sharedInstance;
- (BOOL)isLoaded;
- (void)startLoadingDataIfNeeded;
+ (void)setWorkingDirectory:(NSString *)newLocation;
@end