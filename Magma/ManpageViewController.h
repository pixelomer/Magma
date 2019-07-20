//
//  ManpageViewController.h
//  Magma
//
//  Created by PixelOmer on 20.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ManpageViewController : UIViewController<WKNavigationDelegate, UIScrollViewDelegate> {
	NSString *javascript;
}
@property (nonatomic, readonly, strong) WKWebView *webView;
- (instancetype)initWithPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
