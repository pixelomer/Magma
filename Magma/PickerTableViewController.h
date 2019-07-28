//
//  PickerTableViewController.h
//  Magma
//
//  Created by PixelOmer on 27.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PickerTableViewController;

@protocol PickerTableViewControllerDelegate
@required
- (void)pickerTableViewController:(PickerTableViewController *)vc selectedItemsDidChange:(NSArray *)newItems;
@end

@interface PickerTableViewController : UITableViewController {
	NSArray *visibleOptions;
	NSArray *values;
	NSMutableArray *_selectedOptions;
}
@property (nonatomic, assign) BOOL showsInternalValues;
@property (nonatomic, weak) id<PickerTableViewControllerDelegate> delegate;
@property (nonatomic, copy) NSDictionary<NSString *, id> *options;
@property (nonatomic, assign) BOOL allowsMultipleSelections;
- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options allowsMultipleSelections:(BOOL)allowsMultipleSelections;
- (NSArray<id> *)selectedOptions;
- (void)setSelectedOptions:(NSArray<id> *)selectedOptions;
@end

NS_ASSUME_NONNULL_END
