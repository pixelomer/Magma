//
//  TextFileViewController.m
//  Magma
//
//  Created by PixelOmer on 7.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "TextFileViewController.h"

@implementation TextFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	textView = [UITextView new];
	textView.translatesAutoresizingMaskIntoConstraints = NO;
	textView.scrollEnabled = YES;
	textView.alwaysBounceVertical = YES;
	textView.font = [UIFont systemFontOfSize:15.0];
	textView.backgroundColor = [UIColor clearColor];
	textView.textContainer.lineFragmentPadding = 0.0;
	textView.textContainerInset = UIEdgeInsetsZero;
	textView.layoutManager.usesFontLeading = NO;
	textView.editable = NO;
	textView.contentInset = UIEdgeInsetsMake(5.0, 5.0, 0.0, 5.0);
	textView.text = _text;
	[self.view addSubview:textView];
	[textView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
	[textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
	[textView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
	[textView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
}

- (instancetype)initWithPath:(NSString *)path {
	if ((_text = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil]) && (self = [super init])) {
		return self;
	}
	return nil;
}

@end
