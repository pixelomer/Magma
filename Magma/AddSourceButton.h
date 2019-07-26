//
//  AddSourceButton.h
//  Magma
//
//  Created by PixelOmer on 26.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AddSourceButton : UIButton
@property (nonatomic, strong) NSDictionary *infoDictionary;
+ (instancetype)button;
@end

NS_ASSUME_NONNULL_END
