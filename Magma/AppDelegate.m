#import "AppDelegate.h"
#import "HomeViewController.h"
#import "PackagesViewController.h"
#import "SourcesViewController.h"
#import "PackageSearchViewController.h"
#import "MGViewController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	NSArray *tabs = @[
		@[@(UITabBarSystemItemFeatured),  @"Magma",     @NO],
		@[@(UITabBarSystemItemBookmarks), @"Sources",   @YES],
		@[@(UITabBarSystemItemDownloads), @"Installed", @YES],
		@[@(UITabBarSystemItemSearch),    @"Search",    @YES]
	];
	NSMutableArray *viewControllers = @[
		[HomeViewController alloc],
		[SourcesViewController alloc],
		[PackagesViewController alloc],
		[PackageSearchViewController alloc]
	].mutableCopy;
	for (NSInteger i = 0; i < tabs.count; i++) {
		__kindof MGViewController *rootViewController = viewControllers[i];
		NSArray *itemInfo = tabs[i];
		rootViewController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:[(NSNumber *)itemInfo[0] integerValue] tag:i];
		[rootViewController.tabBarItem setValue:itemInfo[1] forKey:@"internalTitle"];
		rootViewController.waitForDatabase = itemInfo[2];
		viewControllers[i] = [[UINavigationController alloc] initWithRootViewController:[rootViewController init]];
	}
	_rootViewController = [UITabBarController new];
	_rootViewController.view.backgroundColor = [UIColor whiteColor];
	_rootViewController.viewControllers = viewControllers;
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
