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

static UIColor *separatorColor;
static UIFont *headerFont;
static NSArray *cells;

+ (void)load {
	if ([self class] == [PackageDetailsController class]) {
		separatorColor = [UIColor colorWithRed:0.918 green:0.918 blue:0.925 alpha:1.0];
		headerFont = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
		cells = @[
			@[@"Text", @"Details", headerFont],
			NSNull.null,
			@[@"Text", @"Advanced", headerFont],
			NSNull.null,
			@[@"Text", @"Packages File Entry", @"pushFieldsTableView"]
		];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorColor = UIColor.clearColor;
    self.title = _package.package;
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

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.tableView) {
		__kindof UITableViewCell *cell;
		NSArray *rowInfo = cells[indexPath.row];
		if ([rowInfo isKindOfClass:[NSArray class]]) {
			if (rowInfo.count >= 1) {
				if ([rowInfo[0] isEqualToString:@"Text"]) {
					cell = [tableView dequeueReusableCellWithIdentifier:@"text"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"text"];
					if (rowInfo.count >= 2) {
						if ([rowInfo[1] isKindOfClass:[NSString class]]) {
							cell.textLabel.text = rowInfo[1];
						}
						if (rowInfo.count >= 3) {
							if ([rowInfo[2] isKindOfClass:[NSString class]]) {
								cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
								cell.selectionStyle = UITableViewCellSelectionStyleDefault;
								cell.textLabel.textColor = self.navigationController.navigationBar.tintColor;
							}
							else {
								cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryNone;
								cell.selectionStyle = UITableViewCellSelectionStyleNone;
								cell.textLabel.textColor = [UIColor blackColor];
							}
							if ([rowInfo[2] isKindOfClass:[UIFont class]]) {
								cell.textLabel.font = rowInfo[2];
							}
						}
					}
				}
			}
		}
		else if ([rowInfo isKindOfClass:[NSNull class]]) {
			if (!(cell = [tableView dequeueReusableCellWithIdentifier:@"separator"])) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"separator"];
				UIView *separatorView = [UIView new];
				separatorView.backgroundColor = separatorColor;
				separatorView.translatesAutoresizingMaskIntoConstraints = NO;
				[cell.contentView addSubview:separatorView];
				[separatorView.leftAnchor constraintEqualToAnchor:cell.layoutMarginsGuide.leftAnchor].active = YES;
				[separatorView.rightAnchor constraintEqualToAnchor:cell.layoutMarginsGuide.rightAnchor].active = YES;
				[cell.contentView addConstraints:[NSLayoutConstraint
					constraintsWithVisualFormat:@"V:|-1-[separator(==1)]-1-|"
					options:0
					metrics:nil
					views:@{ @"separator" : separatorView }
				]];
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
	return (tableView == self.tableView) ? cells.count : fields.count;
}

- (void)pushFieldsTableView {
	MGTableViewController *fieldsTableViewController = [MGTableViewController new];
	fieldsTableViewController.dataSource = self;
	fieldsTableViewController.delegate = self;
	[self.navigationController pushViewController:fieldsTableViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.tableView) {
		NSArray *rowInfo = cells[indexPath.row];
		if ([rowInfo isKindOfClass:[NSArray class]] && [rowInfo[0] isEqualToString:@"Text"] && rowInfo.count >= 3 && [rowInfo[2] isKindOfClass:[NSString class]]) {
			SEL selector = NSSelectorFromString(rowInfo[2]);
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
