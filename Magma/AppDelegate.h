#import <UIKit/UIKit.h>

#if TARGET_OS_MACCATALYST
@class CatalystSplitViewController;
#endif

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong)
#if TARGET_OS_MACCATALYST
CatalystSplitViewController *
#else
UITabBarController *
#endif
rootViewController;
+ (NSString *)workingDirectory;
@end
