//
//  PreferencesViewController.h
//  Magma
//
//  Created by PixelOmer on 6.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreferencesViewController : UINavigationController<UITableViewDelegate, UITableViewDataSource> {
	UITableViewController *tableViewController;
}
@end

NS_ASSUME_NONNULL_END
