//
//  CatalystSplitViewControllerCell.m
//  Magma
//
//  Created by PixelOmer on 6.10.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#if TARGET_OS_MACCATALYST
#import "CatalystSplitViewControllerCell.h"

@implementation CatalystSplitViewControllerCell

- (void)layoutSubviews {
	[super layoutSubviews];
    self.imageView.bounds = CGRectMake(0, 0, 30, 48);
    self.textLabel.frame = CGRectMake(58, self.textLabel.frame.origin.y+1, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
}

@end
#endif
