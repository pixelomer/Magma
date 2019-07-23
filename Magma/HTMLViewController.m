//
//  HTMLViewController.m
//  Magma
//
//  Created by PixelOmer on 23.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "HTMLViewController.h"
#import "AppDelegate.h"

@implementation HTMLViewController

- (instancetype)initWithPath:(NSString *)path {
	BOOL isDir;
	if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir] && !isDir && (self = [super init]) && (_rootFileURL = [NSURL fileURLWithPath:path])) {
		return self;
	}
	return nil;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
	WKUserScript *userScript = [[WKUserScript alloc] initWithSource:@"var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'width=device-width, initial-scale=1'; document.getElementsByTagName('head')[0].appendChild(meta); window.scrollTo(0, 0);" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
	WKUserContentController *userController = [WKUserContentController new];
	[userController addUserScript:userScript];
	WKWebViewConfiguration *webConfiguration = [WKWebViewConfiguration new];
	webConfiguration.userContentController = userController;
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
    _webView.navigationDelegate = self;
    _webView.allowsBackForwardNavigationGestures = YES;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_webView];
    [_webView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [_webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [_webView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [_webView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    [_webView loadFileURL:_rootFileURL allowingReadAccessToURL:[NSURL fileURLWithPath:AppDelegate.workingDirectory]];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSURL *newURL = navigationAction.request.URL;
	if (newURL.isFileURL) decisionHandler(WKNavigationActionPolicyAllow);
	else {
		decisionHandler(WKNavigationActionPolicyCancel);
		if ([UIApplication.sharedApplication canOpenURL:newURL]) {
			[UIApplication.sharedApplication openURL:newURL];
		}
	}
}

@end
