//
//  AddSourceButton.m
//  Magma
//
//  Created by PixelOmer on 26.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "AddFeaturedSourceButton.h"
#import "Database.h"

@implementation AddFeaturedSourceButton

static UIFont *font;
static UIColor *highlightedColor;

+ (void)load {
	if (self == [AddFeaturedSourceButton class]) {
		font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
		highlightedColor = [UIColor colorWithWhite:1.0 alpha:0.25];
	}
}

+ (instancetype)button {
	AddFeaturedSourceButton *button = [self buttonWithType:UIButtonTypeCustom];
	if (button) {
		button.titleLabel.numberOfLines = 1;
		button.titleLabel.adjustsFontSizeToFitWidth = YES;
		button.titleLabel.lineBreakMode = NSLineBreakByClipping;
		button.titleLabel.textColor = [UIColor whiteColor];
		button.titleLabel.font = font;
		[button setTitle:@"Add" forState:UIControlStateNormal];
		[button setTitleColor:highlightedColor forState:UIControlStateHighlighted];
		[button reloadState];
		[NSNotificationCenter.defaultCenter
			addObserver:button
			selector:@selector(didReceiveNotification:)
			name:DatabaseDidAddSource
			object:Database.sharedInstance
		];
		[NSNotificationCenter.defaultCenter
			addObserver:button
			selector:@selector(didReceiveNotification:)
			name:DatabaseDidRemoveSource
			object:Database.sharedInstance
		];
		[NSNotificationCenter.defaultCenter
			addObserver:button
			selector:@selector(didReceiveNotification:)
			name:DatabaseDidLoad
			object:Database.sharedInstance
		];
	}
	return button;
}

- (void)setInfoDictionary:(NSDictionary *)infoDictionary {
	_infoDictionary = infoDictionary;
	[self reloadState];
}

- (void)didReceiveNotification:(NSNotification *)notification {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self reloadState];
	});
}

- (void)setContentEdgeInsets:(UIEdgeInsets)contentEdgeInsets {
	[super setContentEdgeInsets:UIEdgeInsetsMake(self.contentEdgeInsets.top, contentEdgeInsets.left, self.contentEdgeInsets.bottom, contentEdgeInsets.right)];
}

- (void)reloadState {
	if (!_infoDictionary) return;
	if (!Database.sharedInstance.isLoaded) {
		self.backgroundColor = [UIColor lightGrayColor];
		self.enabled = NO;
		[self setTitle:@"Loading" forState:UIControlStateDisabled];
		[super setContentEdgeInsets:UIEdgeInsetsMake(0.0, self.contentEdgeInsets.left, 2.0, self.contentEdgeInsets.right)];
	}
	else {
		Source *source = nil;
		for (NSString *dist in [(NSDictionary *)_infoDictionary[@"dists"] allValues]) {
			@autoreleasepool {
				NSString *entry = [NSString stringWithFormat:@"deb %@ %@", _infoDictionary[@"url"], dist];
				if ((source = [Database.sharedInstance sourceWithSourcesListEntry:entry])) {
					self.backgroundColor = [UIColor lightGrayColor];
					[self setTitle:@"Added" forState:UIControlStateDisabled];
					self.enabled = NO;
					[super setContentEdgeInsets:UIEdgeInsetsMake(0.0, self.contentEdgeInsets.left, 1.0, self.contentEdgeInsets.right)];
					break;
				}
			}
		}
		if (!source) {
			self.enabled = YES;
			self.backgroundColor = self.tintColor;
			[super setContentEdgeInsets:UIEdgeInsetsMake(0.0, self.contentEdgeInsets.left, 0.0, self.contentEdgeInsets.right)];
		}
	}
}

@end
