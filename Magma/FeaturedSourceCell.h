//
//  FeaturedSourceCell.h
//  Magma
//
//  Created by PixelOmer on 26.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddSourceButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface FeaturedSourceCell : UITableViewCell {
	UIImageView *iconView;
	UIButton *addButton;
	UILabel *titleLabel;
	UILabel *descLabel;
}
@property (nonatomic, readonly, strong) AddSourceButton *addSourceButton;
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void)setInfoDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
