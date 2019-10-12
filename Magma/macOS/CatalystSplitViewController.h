//
//  CatalystSplitViewController.h
//  Magma
//
//  Created by PixelOmer on 22.09.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#if TARGET_OS_MACCATALYST
#import <UIKit/UIKit.h>

@class CatalystSearchProxy;

NS_ASSUME_NONNULL_BEGIN

@interface CatalystSplitViewController : UISplitViewController<UITableViewDataSource, UITableViewDelegate> {
	@private
	UITableViewController *_tableViewController;
	NSArray *_viewControllers;
	UIViewController *_emptyVC;
	CatalystSearchProxy *_searchProxy;
    NSUInteger _realSearchTabIndex;
}
// Negative indexes will be treated as (_viewControllers.count+value)
// Example:
//   viewControllers = @[a, b, c, d];
//   viewControllers.searchTabIndex = @(-1); // Will be treated as 3, which is d
@property (nonatomic, assign) NSNumber *searchTabIndex;
@property (nonatomic, strong, readonly) UISearchBar *searchBar;
@end

NS_ASSUME_NONNULL_END

#endif
