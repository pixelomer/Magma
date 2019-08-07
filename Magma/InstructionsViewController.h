//
//  InstructionsViewController.h
//  Magma
//
//  Created by PixelOmer on 7.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Package;

@interface InstructionsViewController : UIViewController
@property (nonatomic, strong, readonly) NSAttributedString *completeContent;
- (instancetype)initWithPackage:(Package *)package;
@end

NS_ASSUME_NONNULL_END
