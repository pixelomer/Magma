#import "AppDelegate.h"
#import "HomeViewController.h"
#import "DownloadsController.h"
#import "SourcesViewController.h"
#import "PackageSearchViewController.h"
#import "MGViewController.h"
#import "UIImage+ResizeImage.h"

@implementation AppDelegate

static NSString *workingDirectory;

+ (NSString *)workingDirectory {
	if (!workingDirectory) {
		workingDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#if DEBUG
		NSLog(@"Working directory: %@", workingDirectory);
#endif
	}
	return workingDirectory;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[Database.sharedInstance startLoadingDataIfNeeded];
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	NSArray *tabs = @[
		@[@(UITabBarSystemItemFeatured), @NO],
		@[[UIImage imageNamed:@"Storage"], @"Sources", @YES],
		@[@(UITabBarSystemItemDownloads), @NO],
		@[@(UITabBarSystemItemSearch), @YES]
	];
	NSMutableArray *viewControllers = @[
		[HomeViewController new],
		[SourcesViewController new],
		[DownloadsController new],
		[PackageSearchViewController new]
	].mutableCopy;
	for (NSInteger i = 0; i < tabs.count; i++) {
		__kindof MGViewController *rootViewController = viewControllers[i];
		NSArray *itemInfo = tabs[i];
		int waitForDatabaseIndex = 1;
		if ([itemInfo[0] isKindOfClass:[NSNumber class]]) {
			rootViewController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:[(NSNumber *)itemInfo[0] integerValue] tag:i];
		}
		else if (++waitForDatabaseIndex) {
			rootViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:itemInfo[1] image:itemInfo[0] tag:i];
		}
		if ([rootViewController isKindOfClass:[MGViewController class]]) {
			rootViewController.waitForDatabase = itemInfo[waitForDatabaseIndex];
		}
		viewControllers[i] = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	}
	_rootViewController = [UITabBarController new];
	_rootViewController.view.backgroundColor = [UIColor whiteColor];
	_rootViewController.viewControllers = viewControllers;
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
