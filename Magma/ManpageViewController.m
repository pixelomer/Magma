//
//  ManpageViewController.m
//  Magma
//
//  Created by PixelOmer on 20.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "ManpageViewController.h"

@implementation ManpageViewController

- (instancetype)initWithPath:(NSString *)path {
	BOOL isDir;
	if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
		NSMutableString *manpageContents = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		if (manpageContents) {
			NSUInteger rangeLength = 0;
    		NSArray *components = [manpageContents componentsSeparatedByString:@"\n"];
    		for (NSString *component in components) {
    			if ([component.lowercaseString hasPrefix:@".sh"]) {
    				[manpageContents deleteCharactersInRange:NSMakeRange(0, rangeLength)];
    				break;
				}
				else {
					rangeLength += component.length + 1;
				}
			}
			javascript = [NSString stringWithFormat:@"loadManpage('%@')", [[manpageContents dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0] ?: @" "];
    		if ((self = [super init])) {
				return self;
			}
		}
	}
	return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    _webView = [WKWebView new];
    _webView.navigationDelegate = self;
    _webView.scrollView.delegate = self;
    _webView.scrollView.showsHorizontalScrollIndicator = NO;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_webView];
    [_webView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [_webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [_webView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [_webView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    NSURL *manpageHTML = [NSBundle.mainBundle URLForResource:@"manpage" withExtension:@"html"];
    NSURL *accessibleURL = manpageHTML.URLByDeletingLastPathComponent;
    [_webView loadFileURL:manpageHTML allowingReadAccessToURL:accessibleURL];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	[_webView evaluateJavaScript:javascript completionHandler:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.contentOffset.x > 0) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
    }
}

@end
