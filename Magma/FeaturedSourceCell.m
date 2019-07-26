//
//  FeaturedSourceCell.m
//  Magma
//
//  Created by PixelOmer on 26.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "FeaturedSourceCell.h"

@implementation FeaturedSourceCell

static UIFont *titleFont;
static UIFont *descFont;

+ (void)load {
	if (self == [FeaturedSourceCell class]) {
		titleFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
		descFont = [UIFont systemFontOfSize:16.0 weight:UIFontWeightLight];
	}
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		_addSourceButton = [AddSourceButton button];
		_addSourceButton.translatesAutoresizingMaskIntoConstraints = NO;
		iconView = [UIImageView new];
		iconView.contentMode = UIViewContentModeScaleAspectFit;
		iconView.translatesAutoresizingMaskIntoConstraints = NO;
		titleLabel = [UILabel new];
		titleLabel.font = titleFont;
		titleLabel.numberOfLines = 0;
		titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		descLabel = [UILabel new];
		descLabel.font = descFont;
		descLabel.numberOfLines = 0;
		descLabel.translatesAutoresizingMaskIntoConstraints = NO;
		UIView *textContainerView = [UIView new];
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
		[descLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:2.0].active = YES;
		[descLabel.bottomAnchor constraintEqualToAnchor:textContainerView.bottomAnchor].active = YES;
		[self.contentView addSubview:textContainerView]; {
			[textContainerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15.0].active = YES;
			[textContainerView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-15.0].active = YES;
			[textContainerView.rightAnchor constraintEqualToAnchor:self.readableContentGuide.rightAnchor].active = YES;
		}
		[self.contentView addSubview:iconView]; {
			[iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15.0].active = YES;
			[iconView.leftAnchor constraintEqualToAnchor:self.readableContentGuide.leftAnchor constant:2.0].active = YES;
			[iconView.widthAnchor constraintEqualToConstant:50.0].active = YES;
			[iconView.heightAnchor constraintEqualToAnchor:iconView.widthAnchor].active = YES;
		}
		[self.contentView addSubview:_addSourceButton]; {
			[_addSourceButton.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-15.0].active = YES;
			[_addSourceButton.heightAnchor constraintEqualToConstant:20.0].active = YES;
		}
		[_addSourceButton.leftAnchor constraintEqualToAnchor:iconView.leftAnchor].active = YES;
		[_addSourceButton.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:5.0].active = YES;
		[_addSourceButton.rightAnchor constraintEqualToAnchor:iconView.rightAnchor].active = YES;
		[textContainerView.leftAnchor constraintEqualToAnchor:iconView.rightAnchor constant:13.0].active = YES;
	}
	return self;
}

- (void)setInfoDictionary:(NSDictionary *)dict {
	__kindof NSObject *image = dict[@"image"];
	if ([image isKindOfClass:[NSString class]]) {
		image = [UIImage imageNamed:image];
	}
	iconView.image = image ?: [UIImage imageNamed:@"PlaceholderImageName"]; // FIX ME
	titleLabel.text = dict[@"title"];
	descLabel.text = dict[@"description"];
	_addSourceButton.infoDictionary = dict;
}

@end
