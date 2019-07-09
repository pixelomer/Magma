//
//  RelatedPackagesController.h
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "MGTableViewController.h"

@interface RelatedPackagesController : MGTableViewController {
	NSArray *relatedPackages;
}
@property (nonatomic, weak, readonly) Package *package;
@property (nonatomic, copy, readonly) NSString *field;
- (instancetype)initWithPackage:(Package *)package field:(NSString *)field;
@end
