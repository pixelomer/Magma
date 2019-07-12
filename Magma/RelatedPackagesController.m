//
//  RelatedPackagesController.m
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "RelatedPackagesController.h"
#import "Package.h"
#import "PackageDetailsController.h"

@implementation RelatedPackagesController

- (instancetype)initWithPackage:(Package *)package field:(NSString *)field {
	if ([package parse] && package[field].length && (self = [super init])) {
		_package = package;
		_field = field;
		NSMutableArray *mRelatedPackages = [NSMutableArray new];
		NSArray *fieldComponents = [package[field] componentsSeparatedByString:@", "];
		for (NSString *fieldComponent in fieldComponents) {
			if (fieldComponent.length) {
				NSArray *options = [fieldComponent componentsSeparatedByString:@" | "];
				for (NSString *option in options) {
					NSMutableArray *parts = [option componentsSeparatedByString:@" "].mutableCopy;
					NSString *packageName = parts[0];
					[parts removeObjectAtIndex:0];
					NSString *restOfTheField = [parts componentsJoinedByString:@" "];
					Package *relatedPackage = [Database.sharedInstance packageWithIdentifier:packageName];
					if (relatedPackage) {
						[mRelatedPackages addObject:@[relatedPackage, restOfTheField]];
					}
					else {
						[mRelatedPackages addObject:@[packageName, restOfTheField]];
					}
				}
			}
		}
		relatedPackages = mRelatedPackages.copy;
		return self;
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return relatedPackages.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *relatedPackageInfo = relatedPackages[indexPath.row];
	Package *package = relatedPackageInfo[0];
	PackageDetailsController *vc = ([package isKindOfClass:[Package class]]) ? [[PackageDetailsController alloc] initWithPackage:package] : nil;
	[self pushViewController:vc animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
	NSArray *relatedPackageInfo = relatedPackages[indexPath.row];
	if ([relatedPackageInfo[0] isKindOfClass:[NSString class]]) {
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", relatedPackageInfo[0], relatedPackageInfo[1]];
		cell.detailTextLabel.text = @"(Unknown package)";
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else {
		Package *package = relatedPackageInfo[0];
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", package.package, relatedPackageInfo[1]];
		cell.detailTextLabel.text = package.shortDescription;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end
