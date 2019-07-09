//
//  PackageDetailsController.h
//  Magma
//
//  Created by PixelOmer on 5.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

//	The UI for this view controller is a UITableView.
//	You might think this is crazy but I think this is the easiest way.

#import "MGTableViewController.h"

@class Package;

@interface PackageDetailsController : MGTableViewController {
	NSArray *fields;
	NSArray *filteredCells;
}
@property (nonatomic, readonly, weak) Package *package;
- (instancetype)initWithPackage:(Package *)package;
@end
