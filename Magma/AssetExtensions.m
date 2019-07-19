//
//  AssetExtensions.m
//  Magma
//
//  Created by PixelOmer on 18.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "AssetExtensions.h"
#import "UIImage+ResizeImage.h"

@implementation UIImage(Assets)

static UIImage *folderIcon;
+ (UIImage *)folderIcon {
	return folderIcon ?: (folderIcon = [[[UIImage imageNamed:@"Folder"] resizedImageOfSize:CGSizeMake(36, 36)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]);
}

static UIImage *fileIcon;
+ (UIImage *)fileIcon {
	return fileIcon ?: (fileIcon = [[UIImage imageNamed:@"File"] resizedImageOfSize:CGSizeMake(36, 36)]);
}

@end

@implementation UIColor(Assets)

static UIColor *folderTintColor;
+ (UIColor *)folderTintColor {
	return folderTintColor ?: (folderTintColor = [UIColor colorWithRed:0.435 green:0.811 blue:0.922 alpha:1.0]);
}

@end
