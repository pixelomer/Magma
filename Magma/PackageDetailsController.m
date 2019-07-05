//
//  PackageDetailsController.m
//  Magma
//
//  Created by PixelOmer on 5.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "PackageDetailsController.h"
#import "Package.h"

@implementation PackageDetailsController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (instancetype)init {
	@throw [NSException exceptionWithName:NSInvalidArgumentException
		reason:[NSString stringWithFormat:@"-[%@ init] is not allowed, use -[%@ initWithPackage:] instead.", NSStringFromClass(self.class), NSStringFromClass(self.class)]
		userInfo:nil
	];
}

- (instancetype)initWithPackage:(Package *)package {
	if (package && (self = [super init])) {
		_package = package;
		NSMutableArray *mFields = [NSMutableArray new];
		NSDictionary *rawPackage = package.rawPackage.copy;
		for (NSString *fieldName in rawPackage) {
			NSString *fieldValue = rawPackage[fieldName];
			/*
			 * Do some filtering here
			 */
			[mFields addObject:@[fieldName, fieldValue]];
		}
		fields = mFields.copy;
	}
	return self;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0: return @"Fields";
		default: return nil;
	}
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"cell"];
	NSArray *cellContents = fields[indexPath.row];
	cell.textLabel.text = cellContents[0];
	cell.detailTextLabel.text = cellContents[1];
	cell.detailTextLabel.numberOfLines = 2;
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return fields.count;
}

@end
