//
//  TextViewCell.m
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "TextViewCell.h"

@implementation TextViewCell

static UIFont *font;

+ (void)load {
	if ([self class] == [TextViewCell class]) {
		font = [UIFont systemFontOfSize:17.0];
	}
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		textView = [UITextView new];
		textView.translatesAutoresizingMaskIntoConstraints = NO;
		textView.scrollEnabled = NO;
		textView.font = font;
		textView.layer.borderWidth = 0.0;
		textView.backgroundColor = [UIColor clearColor];
		textView.textContainer.lineFragmentPadding = 0.0;
		textView.textContainerInset = UIEdgeInsetsZero;
		textView.layoutManager.usesFontLeading = NO;
		textView.editable = NO;
		[self.contentView addSubview:textView];
		[textView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
		[textView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-7.5].active = YES;
		[textView.heightAnchor constraintGreaterThanOrEqualToConstant:0.0].active = YES;
		[textView.leftAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leftAnchor].active = YES;
		[textView.rightAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.rightAnchor].active = YES;
	}
	return self;
}

- (NSString *)textViewText {
	return textView.text;
}

- (void)setTextViewText:(NSString *)text {
	textView.text = text;
}

@end
