//
//  PackageDetailsController.m
//  Magma
//
//  Created by PixelOmer on 5.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "PackageDetailsController.h"
#import "Package.h"
#import <objc/runtime.h>

@implementation PackageDetailsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _package.package;
    sections = @[
    	@"Advanced"
    ];
    cells = @[
    	@[
    		@[@"Packages File Entry", @"pushFieldsTableView"]
		]
	];
}

- (instancetype)init {
	@throw [NSException exceptionWithName:NSInvalidArgumentException
		reason:[NSString stringWithFormat:@"-[%@ init] is not allowed, use -[%@ initWithPackage:] instead.", NSStringFromClass(self.class), NSStringFromClass(self.class)]
		userInfo:nil
	];
}

- (instancetype)initWithPackage:(Package *)package {
	if (package && (self = [super init])) {
		[(_package = package) parse];
		NSMutableArray *mFields = [NSMutableArray new];
		NSDictionary *rawPackage = package.rawPackage.copy;
		for (NSString *fieldName in rawPackage) [mFields addObject:@[fieldName, rawPackage[fieldName]]];
		fields = mFields.copy;
	}
	return self;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.tableView) {
		return sections[section];
	}
	else {
		return nil;
	}
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.tableView) {
		NSArray *rowInfo = cells[indexPath.section][indexPath.row];
		__kindof UITableViewCell *cell;
		if ([rowInfo[0] isKindOfClass:NSString.class]) {
			cell = [tableView dequeueReusableCellWithIdentifier:@"text"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"text"];
			cell.textLabel.text = rowInfo[0];
		}
		else {
			cell = rowInfo[0];
		}
		if (rowInfo.count > 1) {
			if ([rowInfo[1] isKindOfClass:NSString.class]) {
				cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			}
			else {
				cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryNone;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
		}
		return cell;
	}
	else {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
		NSArray *cellContents = fields[indexPath.row];
		cell.textLabel.text = cellContents[0];
		cell.detailTextLabel.text = cellContents[1];
		cell.detailTextLabel.numberOfLines = cell.textLabel.numberOfLines = 1;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (tableView == self.tableView) ? cells[section].count : fields.count;
}

- (void)pushFieldsTableView {
	MGTableViewController *fieldsTableViewController = [MGTableViewController new];
	fieldsTableViewController.dataSource = self;
	fieldsTableViewController.delegate = self;
	[self.navigationController pushViewController:fieldsTableViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.tableView) {
		NSArray *rowInfo = cells[indexPath.section][indexPath.row];
		if (rowInfo.count > 1 && [rowInfo[1] isKindOfClass:[NSString class]]) {
			SEL selector = NSSelectorFromString(rowInfo[1]);
			((void(*)(PackageDetailsController *, SEL))class_getMethodImplementation(self.class, selector))(self, selector);
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return (tableView != self.tableView) && (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if ((tableView != self.tableView) && (action == @selector(copy:))){
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		[[UIPasteboard generalPasteboard] setString:cell.detailTextLabel.text];
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (tableView != self.tableView);
}

@end
