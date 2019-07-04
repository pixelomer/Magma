#import "AppDelegate.h"
#import "HomeViewController.h"
#import "DownloadsController.h"
#import "SourcesViewController.h"
#import "PackageSearchViewController.h"
#import "MGViewController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	Database.workingDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
	[Database.sharedInstance startLoadingDataIfNeeded];
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	NSArray *tabs = @[
		@[@(UITabBarSystemItemRecents),   @NO],
		@[@"Database",                    @YES],
		@[@(UITabBarSystemItemDownloads), @YES],
		@[@(UITabBarSystemItemSearch),    @YES]
	];
	NSMutableArray *viewControllers = @[
		[HomeViewController alloc],
		[SourcesViewController alloc],
		[DownloadsController alloc],
		[PackageSearchViewController alloc]
	].mutableCopy;
	for (NSInteger i = 0; i < tabs.count; i++) {
		__kindof MGViewController *rootViewController = viewControllers[i];
		NSArray *itemInfo = tabs[i];
		if ([itemInfo[0] isKindOfClass:[NSNumber class]]) {
			rootViewController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:[(NSNumber *)itemInfo[0] integerValue] tag:i];
		}
		else {
			rootViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:itemInfo[0]] tag:i];
		}
		rootViewController.waitForDatabase = itemInfo[1];
		viewControllers[i] = [[UINavigationController alloc] initWithRootViewController:[rootViewController init]];
	}
	_rootViewController = [UITabBarController new];
	_rootViewController.view.backgroundColor = [UIColor whiteColor];
	_rootViewController.viewControllers = viewControllers;
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
