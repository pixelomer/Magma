//
//  CatalystSplitViewController.h
//  Magma
//
//  Created by PixelOmer on 22.09.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CatalystSplitViewController : UISplitViewController<UITableViewDataSource, UITableViewDelegate> {
	UITableViewController *_tableViewController;
	NSArray *_viewControllers;
}
@end

NS_ASSUME_NONNULL_END

#endif
