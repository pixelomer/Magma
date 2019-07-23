//
//  HTMLViewController.h
//  Magma
//
//  Created by PixelOmer on 23.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTMLViewController : UIViewController<WKNavigationDelegate>
@property (nonatomic, copy, readonly) NSURL *rootFileURL;
@property (nonatomic, strong, readonly) WKWebView *webView;
@end

NS_ASSUME_NONNULL_END
