//
//  AddSourceViewController.h
//  Magma
//
//  Created by PixelOmer on 27.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGTableViewController.h"
#import "PickerTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddSourceViewController : UINavigationController<UITableViewDelegate, UITableViewDataSource, PickerTableViewControllerDelegate> {
	UITableViewController *tableViewController;
	NSMutableArray<NSArray *> *selectedOptions;
}
@property (nonatomic, copy, readonly) NSDictionary *infoDictionary;
- (instancetype)initWithInformationDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
