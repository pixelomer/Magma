#import <TargetConditionals.h>
#import <Magma/macOS/CatalystSplitViewController.h>
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
#if JAILBROKEN
		workingDirectory = @"/var/mobile/Documents/Magma";
#else
		workingDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#endif
		NSLog(@"Working directory: %@", workingDirectory);
	}
	return workingDirectory;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[Database.sharedInstance startLoadingDataIfNeeded];
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	#if TARGET_OS_MACCATALYST
	#define star [UIImage systemImageNamed:@"star.fill"]
	#define downloads [UIImage systemImageNamed:@"square.and.arrow.down.fill"]
	#define search [UIImage systemImageNamed:@"magnifyingglass"]
	#else
	#define star @(UITabBarSystemItemFeatured)
	#define downloads @(UITabBarSystemItemDownloads)
	#define search @(UITabBarSystemItemSearch)
	#endif
	NSArray *tabs = @[
		@[star, @"Featured", @NO],
		@[[UIImage imageNamed:@"Storage"], @"Sources", @YES],
		@[downloads, @"Downloads", @NO],
		@[search, @"Search", @YES]
	];
	#undef star
	#undef downloads
	#undef search
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
#if TARGET_OS_MACCATALYST
	_rootViewController = [CatalystSplitViewController new];
	_rootViewController.viewControllers = viewControllers;
	_window.windowScene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
	_window.windowScene.titlebar.autoHidesToolbarInFullScreen = YES;
#else
	_rootViewController = [UITabBarController new];
	_rootViewController.viewControllers = viewControllers;
#endif
	_rootViewController.view.backgroundColor = [UIColor systemGray6Color];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
