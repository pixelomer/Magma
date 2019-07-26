//
//  FeaturedSourceCell.h
//  Magma
//
//  Created by PixelOmer on 26.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeaturedSourceCell : UITableViewCell {
	UIImageView *iconView;
	UILabel *titleLabel;
	UILabel *descLabel;
}
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void)setInformationDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
