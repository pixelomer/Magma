//
//  TextFileViewController.h
//  Magma
//
//  Created by PixelOmer on 7.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextFileViewController : UIViewController {
	UITextView *textView;
}
@property (nonatomic, strong, readonly) NSString *text;
@end

NS_ASSUME_NONNULL_END
