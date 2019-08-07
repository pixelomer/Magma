//
//  InstructionsViewController.m
//  Magma
//
//  Created by PixelOmer on 7.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "InstructionsViewController.h"
#import "Package.h"
#import "Source.h"

@implementation InstructionsViewController

static NSAttributedString *incompleteContent;

+ (void)load {
	if (self == [InstructionsViewController class]) {
		NSMutableAttributedString *string = [NSMutableAttributedString new];
		NSDictionary *headerAttributes = @{
			NSFontAttributeName : [UIFont systemFontOfSize:25 weight:UIFontWeightBold],
			NSBackgroundColorAttributeName : [UIColor clearColor],
			NSForegroundColorAttributeName : [UIColor blackColor]
		};
		NSDictionary *textAttributes = @{
			NSFontAttributeName : [UIFont systemFontOfSize:17],
			NSBackgroundColorAttributeName : [UIColor clearColor],
			NSForegroundColorAttributeName : [UIColor blackColor]
		};
		NSDictionary *boldTextAttributes = @{
			NSFontAttributeName : [UIFont systemFontOfSize:17 weight:UIFontWeightBold],
			NSBackgroundColorAttributeName : [UIColor clearColor],
			NSForegroundColorAttributeName : [UIColor blackColor]
		};
		NSDictionary *inlineCodeAttributes = @{
			NSFontAttributeName : [UIFont fontWithName:@"Courier" size:17],
			NSBackgroundColorAttributeName : [UIColor clearColor],
			NSForegroundColorAttributeName : [UIColor redColor]
		};
		NSMutableParagraphStyle *codeBlockParagpraph = [NSMutableParagraphStyle new];
#define indent 17
		codeBlockParagpraph.firstLineHeadIndent = indent;
		codeBlockParagpraph.headIndent = indent;
		codeBlockParagpraph.tailIndent = -indent;
#undef indent
		NSDictionary *codeBlockAttributes = @{
			NSFontAttributeName : [UIFont fontWithName:@"Courier" size:17],
			NSBackgroundColorAttributeName : [UIColor blackColor],
			NSForegroundColorAttributeName : [UIColor whiteColor],
			NSParagraphStyleAttributeName : codeBlockParagpraph
		};
		NSDictionary *separatorSpace = @{
			NSFontAttributeName : [UIFont systemFontOfSize:8],
			NSBackgroundColorAttributeName : textAttributes[NSBackgroundColorAttributeName],
			NSForegroundColorAttributeName : textAttributes[NSForegroundColorAttributeName]
		};
		NSDictionary *codeBlockMarginAttributes = @{
			NSFontAttributeName : [UIFont systemFontOfSize:4],
			NSBackgroundColorAttributeName : codeBlockAttributes[NSBackgroundColorAttributeName],
			NSForegroundColorAttributeName : codeBlockAttributes[NSForegroundColorAttributeName]
		};
		NSArray<NSArray *> *stringParts = @[
			@[@"Requirements\n", headerAttributes],
			@[@"\n", separatorSpace],
			@[@"- A device running Debian or one of its distributions with <arch> architecture\n- An internet connection\n", textAttributes],
			@[@"\n", separatorSpace],
			@[@"Instructions\n", headerAttributes],
			@[@"\n", separatorSpace],
			@[@"1. ", boldTextAttributes],
			@[@"Make sure you have the following entry either inside of the ", textAttributes],
			@[@"/etc/apt/sources.list", inlineCodeAttributes],
			@[@" file or inside of another ", textAttributes],
			@[@".list", inlineCodeAttributes],
			@[@" file within the ", textAttributes],
			@[@"/etc/apt/sources.list.d", inlineCodeAttributes],
			@[@" directory. You might also need to import the public keys for the repository.\n", textAttributes],
			@[@"\n", separatorSpace],
			@[@" \n", codeBlockMarginAttributes],
			@[@"<entry>", codeBlockAttributes],
			@[@"\n \n", codeBlockMarginAttributes],
			@[@"\n", separatorSpace],
			@[@"2. ", boldTextAttributes],
			@[@"Fetch the newest files by executing the following command as root.\n", textAttributes],
			@[@"\n", separatorSpace],
			@[@" \n", codeBlockMarginAttributes],
			@[@"apt-get update", codeBlockAttributes],
			@[@"\n \n", codeBlockMarginAttributes],
			@[@"\n", separatorSpace],
			@[@"3. ", boldTextAttributes],
			@[@"Install the package by executing the following command as root.\n", textAttributes],
			@[@"\n", separatorSpace],
			@[@" \n", codeBlockMarginAttributes],
			@[@"apt-get install <package>", codeBlockAttributes],
			@[@"\n \n", codeBlockMarginAttributes],
			@[@"\n", separatorSpace],
		];
		for (NSArray *array in stringParts) {
			[string appendAttributedString:[[NSAttributedString alloc] initWithString:array[0] attributes:array[1]]];
		}
		incompleteContent = string.copy;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Installation";
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.bounces = YES;
    scrollView.alwaysBounceVertical = YES;
	scrollView.alwaysBounceHorizontal = NO;
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.attributedText = _completeContent;
    [scrollView addSubview:label];
    [label.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:15.0].active = YES;
    [label.bottomAnchor constraintLessThanOrEqualToAnchor:scrollView.bottomAnchor].active = YES;
    [label.leftAnchor constraintEqualToAnchor:scrollView.readableContentGuide.leftAnchor].active = YES;
    [label.rightAnchor constraintEqualToAnchor:scrollView.readableContentGuide.rightAnchor].active = YES;
    [self.view addSubview:scrollView];
    [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [scrollView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    [scrollView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
}

- (instancetype)initWithPackage:(Package *)package {
	if ([package parse] && (self = [super init])) {
		NSMutableAttributedString *completeContent = incompleteContent.mutableCopy;
		NSString *arch = (package.architecture ?: @"any");
		arch = ([arch isEqualToString:@"all"] ? @"any" : arch);
		[completeContent.mutableString replaceOccurrencesOfString:@"<arch>" withString:arch options:0 range:NSMakeRange(0, completeContent.mutableString.length)];
		[completeContent.mutableString replaceOccurrencesOfString:@"<entry>" withString:[package.source sourcesListEntryWithComponents:YES] options:0 range:NSMakeRange(0, completeContent.mutableString.length)];
		[completeContent.mutableString replaceOccurrencesOfString:@"<package>" withString:package.package options:0 range:NSMakeRange(0, completeContent.mutableString.length)];
		_completeContent = completeContent.copy;
		return self;
	}
	return nil;
}

@end
