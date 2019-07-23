//
//  ManpageViewController.m
//  Magma
//
//  Created by PixelOmer on 20.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "ManpageViewController.h"
#import <man2html/man2html.h>

@implementation ManpageViewController

- (instancetype)initWithPath:(NSString *)path {
	BOOL isDir;
	if (path.pathComponents.count >= 3 && [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
		NSMutableArray *pathComponents = path.pathComponents.mutableCopy;
		if ([pathComponents[0] isEqualToString:@"/"]) {
			if (pathComponents.count >= 4) [pathComponents removeObjectAtIndex:0];
			else return nil;
		}
		NSString *finalPath;
		//        -3     -2   -1
		// -> /manpages/man1/owo.1
		if ([pathComponents[pathComponents.count-3] isEqualToString:@"manpages"]) {
			pathComponents[pathComponents.count-3] = @"parsed_manpages";
			finalPath = [NSString stringWithFormat:@"/%@.html", [pathComponents componentsJoinedByString:@"/"]];
		}
		else {
			finalPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.html", NSUUID.UUID.UUIDString]];
		}
		if ([NSFileManager.defaultManager createDirectoryAtPath:finalPath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil]) {
			if (![NSFileManager.defaultManager fileExistsAtPath:finalPath]) {
				if (!parse_manpage(path.UTF8String, finalPath.UTF8String)) {
					[NSFileManager.defaultManager removeItemAtPath:finalPath error:nil];
					return nil;
				}
			}
			NSURL *htmlURL = [NSURL fileURLWithPath:finalPath];
			if (htmlURL && (self = [super init])) {
				self->htmlURL = htmlURL;
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
	WKUserScript *userScript = [[WKUserScript alloc] initWithSource:@"var style = document.createElement('style'); style.innerHTML = 'body{font-family: verdana, helvetica, arial, sans-serif;}'; document.getElementsByTagName('head')[0].appendChild(style); var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'width=device-width, initial-scale=1'; document.getElementsByTagName('head')[0].appendChild(meta); window.scrollTo(0, 0);" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
	WKUserContentController *userController = [WKUserContentController new];
	[userController addUserScript:userScript];
	WKWebViewConfiguration *webConfiguration = [WKWebViewConfiguration new];
	webConfiguration.userContentController = userController;
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
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
    [_webView loadFileURL:htmlURL allowingReadAccessToURL:htmlURL];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSURL *newURL = navigationAction.request.URL;
	if ([newURL.absoluteString isEqualToString:htmlURL.absoluteString]) decisionHandler(WKNavigationActionPolicyAllow);
	else {
		decisionHandler(WKNavigationActionPolicyCancel);
		if ([UIApplication.sharedApplication canOpenURL:newURL]) {
			[UIApplication.sharedApplication openURL:newURL];
		}
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
}

- (void)dealloc {
	NSLog(@"Deallocating...");
}

@end
