#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong)
#if TARGET_OS_MACCATALYST
UISplitViewController *
#else
UITabBarController *
#endif
rootViewController;
+ (NSString *)workingDirectory;
@end
