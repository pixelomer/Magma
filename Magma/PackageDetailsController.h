//
//  PackageDetailsController.h
//  Magma
//
//  Created by PixelOmer on 5.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "MGTableViewController.h"

@class Package;

@interface PackageDetailsController : MGTableViewController {
	NSArray *fields;
	NSArray<NSString *> *sections;
	NSArray<NSArray<NSArray<NSString *> *> *> *cells; // [i][0] = title, [i][1] = action
}
@property (nonatomic, readonly, strong) Package *package;
- (instancetype)initWithPackage:(Package *)package;
@end
