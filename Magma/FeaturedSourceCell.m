//
//  FeaturedSourceCell.m
//  Magma
//
//  Created by PixelOmer on 26.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "FeaturedSourceCell.h"

@implementation FeaturedSourceCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		iconView = [UIImageView new];
		titleLabel = [UILabel new];
		titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
		titleLabel.numberOfLines = 0;
		descLabel = [UILabel new];
		descLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightLight];
		descLabel.numberOfLines = 0;
		UIView *textContainerView = [UIView new];
		iconView.translatesAutoresizingMaskIntoConstraints = NO;
		titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		descLabel.translatesAutoresizingMaskIntoConstraints = NO;
		textContainerView.translatesAutoresizingMaskIntoConstraints = NO;
		[textContainerView addSubview:titleLabel];
		[textContainerView addSubview:descLabel];
		@autoreleasepool {
			NSArray *views = @[titleLabel, descLabel];
			for (UIView *view in views) {
				[view.leftAnchor constraintEqualToAnchor:textContainerView.leftAnchor constant:5.0].active = YES;
				[view.rightAnchor constraintEqualToAnchor:textContainerView.rightAnchor].active = YES;
				[view.heightAnchor constraintGreaterThanOrEqualToConstant:0.0].active = YES;
			}
		}
		[titleLabel.topAnchor constraintEqualToAnchor:textContainerView.topAnchor].active = YES;
		[descLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor].active = YES;
		[descLabel.bottomAnchor constraintEqualToAnchor:textContainerView.bottomAnchor].active = YES;
		[self.contentView addSubview:textContainerView]; {
			[textContainerView.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:15.0].active = YES;
			[textContainerView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-15.0].active = YES;
			[textContainerView.rightAnchor constraintEqualToAnchor:self.readableContentGuide.rightAnchor];
		}
		[self.contentView addSubview:iconView]; {
			[iconView.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:15.0].active = YES;
			[iconView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-15.0].active = YES;
			[iconView.leftAnchor constraintEqualToAnchor:self.readableContentGuide.leftAnchor].active = YES;
			[iconView.heightAnchor constraintEqualToConstant:50.0].active = YES;
		}
		[self.contentView addConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"[icon(50)][text]"
			options:NSLayoutFormatAlignAllCenterY
			metrics:nil
			views:@{ @"icon" : iconView, @"text" : textContainerView }
		]];
		[textContainerView.leftAnchor constraintEqualToAnchor:iconView.rightAnchor].active = YES;
		[textContainerView.rightAnchor constraintEqualToAnchor:self.readableContentGuide.rightAnchor].active = YES;
	}
	return self;
}

- (void)setInformationDictionary:(NSDictionary *)dict {
	__kindof NSObject *image = dict[@"image"];
	if ([image isKindOfClass:[NSString class]]) {
		image = [UIImage imageNamed:image];
	}
	iconView.image = image;
	titleLabel.text = dict[@"title"];
	descLabel.text = dict[@"description"];
}

@end
