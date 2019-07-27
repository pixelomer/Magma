//
//  PickerTableViewController.h
//  Magma
//
//  Created by PixelOmer on 27.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PickerTableViewController : UITableViewController {
	NSArray *visibleOptions;
	NSArray *values;
}
@property (nonatomic, copy) NSDictionary<NSString *, id> *options;
@property (nonatomic, strong) NSArray<id> *selectedOptions;
@property (nonatomic, assign) BOOL allowsMultipleSelections;
- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options allowsMultipleSelections:(BOOL)allowsMultipleSelections;
@end

NS_ASSUME_NONNULL_END
