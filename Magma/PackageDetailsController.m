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
#import "RelatedPackagesController.h"
#import "TextViewCell.h"
#import "DownloadManager.h"
#import <MessageUI/MessageUI.h>

@implementation PackageDetailsController

static UIColor *separatorColor;
static UIFont *headerFont;
static NSArray *allCells;
static UIFont *defaultFont;

+ (void)load {
	if ([self class] == [PackageDetailsController class]) {
		NSArray *selectors = @[
			@"showConflicts",
			@"showProvides",
			@"showBreaks"
		];
		for (NSString *selectorString in selectors) {
			SEL selector = NSSelectorFromString(selectorString);
			class_addMethod(self, selector, class_getMethodImplementation(self, @selector(showDepends)), "v@:");
		}
		selectors = nil;
		separatorColor = [UIColor colorWithRed:0.918 green:0.918 blue:0.925 alpha:1.0];
		headerFont = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
		defaultFont = [UIFont systemFontOfSize:17];
		allCells = @[
			@[@"Text", @"Description", headerFont],
			@[@"Data", @"longDescription"],
			NSNull.null,
			@[@"Text", @"Details", headerFont],
			@{@"Version" : @"version"},
			@[@"Text", @"Installation Instructions", @"showInstallationInstructions"],
			NSNull.null,
			@[@"Text", @"Relations", headerFont],
			@[@"Text", @"Dependencies", @"showDepends", @"depends"],
			@[@"Text", @"Conflicts", @"showConflicts", @"conflicts"],
			@[@"Text", @"Provided Packages", @"showProvides", @"provides"],
			@[@"Text", @"Broken Packages", @"showBreaks", @"breaks"],
			@[@"Text", @"No relations.", @(4)],
			NSNull.null,
			@[@"Text", @"Contact", headerFont],
			@[@"Text", @"Contact Author", @"openMailApp:", @"author"],
			@[@"Text", @"Contact Maintainer", @"openMailApp:", @"maintainer"],
			@[@"Text", @"Visit Homepage", @"openURL:", @"homepage"],
			@[@"Text", @"Report a Bug", @"openURL:", @"bugs"],
			NSNull.null,
			@[@"Text", @"Advanced", headerFont],
			@[@"Text", @"Packages File Entry", @"pushFieldsTableView"]
		];
	}
}

- (void)showDepends {
	NSString *field = [NSStringFromSelector(_cmd) substringFromIndex:4].lowercaseString;
	RelatedPackagesController *vc = [[RelatedPackagesController alloc] initWithPackage:_package field:field];
	[self pushViewController:vc animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *getButton = [[UIBarButtonItem alloc] initWithTitle:@"Get" style:UIBarButtonItemStylePlain target:self action:@selector(getPackage)];
    self.navigationItem.rightBarButtonItem = getButton;
    self.tableView.separatorColor = UIColor.clearColor;
    self.title = _package.name ?: _package.package;
}

- (void)getPackage {
	[DownloadManager.sharedInstance startDownloadingPackage:_package];
	self.tabBarController.selectedIndex = 2;
}

- (instancetype)init {
	@throw [NSException exceptionWithName:NSInvalidArgumentException
		reason:[NSString stringWithFormat:@"-[%@ init] is not allowed, use -[%@ initWithPackage:] instead.", NSStringFromClass(self.class), NSStringFromClass(self.class)]
		userInfo:nil
	];
}

- (void)showInstallationInstructions {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Not Implemented" message:@"This part of the application is not implemented yet. If you are an end user and this is a final build, you shouldn't be seeing this. Please report this to the developer." preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (instancetype)initWithPackage:(Package *)package {
	if ([package parse] && (self = [super init])) {
		_package = package;
		NSMutableArray *mFields = [NSMutableArray new];
		NSDictionary *rawPackage = package.rawPackage.copy;
		for (NSString *fieldName in rawPackage) [mFields addObject:@[fieldName, rawPackage[fieldName]]];
		fields = mFields.copy;
		NSMutableArray *filteredCells = allCells.mutableCopy;
		int failedCheckCounter = 0;
		for (NSInteger i = 0; i < filteredCells.count; i++) {
			NSArray *cell = filteredCells[i];
			NSInteger previousCount = filteredCells.count;
			if ([cell isKindOfClass:[NSArray class]]) {
				if (((cell.count >= 4) && !package[cell[3]].length) || ((cell.count >= 3) && [cell[2] isKindOfClass:[NSNumber class]] && (failedCheckCounter != [(NSNumber *)cell[2] intValue]))) {
					[filteredCells removeObjectAtIndex:i];
				}
			}
			if (previousCount != filteredCells.count) {
				i--;
				failedCheckCounter++;
			}
			else failedCheckCounter = 0;
		}
		self->filteredCells = filteredCells.copy;
		return self;
	}
	return nil;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.tableView) {
		__kindof UITableViewCell *cell;
		NSArray *rowInfo = filteredCells[indexPath.row];
		BOOL allowsSelection = NO;
		if ([rowInfo isKindOfClass:[NSDictionary class]]) {
			cell = [tableView dequeueReusableCellWithIdentifier:@"value"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"value"];
			cell.textLabel.text = [(NSDictionary *)rowInfo allKeys][0];
			cell.detailTextLabel.text = _package[[(NSDictionary *)rowInfo allValues][0]];
		}
		if ([rowInfo isKindOfClass:[NSArray class]]) {
			if (rowInfo.count >= 1) {
				if ([rowInfo[0] isEqualToString:@"Text"]) {
					cell = [tableView dequeueReusableCellWithIdentifier:@"text"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"text"];
					cell.textLabel.font = defaultFont;
					if (rowInfo.count >= 2) {
						if ([rowInfo[1] isKindOfClass:[NSString class]]) {
							cell.textLabel.text = rowInfo[1];
						}
						else cell.textLabel.text = @"";
						if (rowInfo.count >= 3) {
							if ([rowInfo[2] isKindOfClass:[NSString class]]) {
								allowsSelection = YES;
							}
							else if ([rowInfo[2] isKindOfClass:[UIFont class]]) {
								cell.textLabel.font = rowInfo[2];
							}
						}
					}
				}
				else if ([rowInfo[0] isEqualToString:@"Data"]) {
					cell = [tableView dequeueReusableCellWithIdentifier:@"textViewCell"] ?: [[TextViewCell alloc] initWithReuseIdentifier:@"textViewCell"];
					[(TextViewCell *)cell setTextViewText:[_package valueForKey:rowInfo.lastObject]];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
		if (allowsSelection) {
			cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			cell.textLabel.textColor = self.navigationController.navigationBar.tintColor;
		}
		else {
			cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.textColor = [UIColor blackColor];
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
	return (tableView == self.tableView) ? filteredCells.count : fields.count;
}

- (void)openMailApp:(NSString *)field {
	NSString *fullString = _package[field];
	if (fullString) {
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\<(.*)\\>" options:0 error:nil];
		NSTextCheckingResult *regexResult = [regex firstMatchInString:fullString options:0 range:NSMakeRange(0, fullString.length)];
		if (regexResult && regexResult.range.location != NSNotFound) {
			NSString *email = [fullString substringWithRange:regexResult.range];
			NSURL *emailURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
			if ([UIApplication.sharedApplication canOpenURL:emailURL]) {
				[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
				[UIApplication.sharedApplication openURL:emailURL];
			}
			else {
				[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
				if ([MFMailComposeViewController canSendMail]) {
					MFMailComposeViewController *composeVC = [[MFMailComposeViewController alloc] init];
					[composeVC setToRecipients:@[email]];
					[self presentViewController:composeVC animated:YES completion:nil];
				}
				else {
					UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Send Mail" message:@"Make sure you have an email client installed and have a usable email address." preferredStyle:UIAlertControllerStyleAlert];
					[alert addAction:[UIAlertAction
						actionWithTitle:@"OK"
						style:UIAlertActionStyleCancel
						handler:nil
					]];
					[self presentViewController:alert animated:YES completion:nil];
				}
			}
			return;
		}
	}
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Address Available" message:@"The package doesn't contain an email address." preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction
		actionWithTitle:@"OK"
		style:UIAlertActionStyleCancel
		handler:nil
	]];
	[self presentViewController:alert animated:YES completion:nil];
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)openURL:(NSString *)field {
	NSURL *URL = [NSURL URLWithString:_package[field]];
	if (URL && [UIApplication.sharedApplication canOpenURL:URL]) {
		[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
		[UIApplication.sharedApplication openURL:URL];
		return;
	}
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid URL" message:@"The package provided an invalid URL." preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction
		actionWithTitle:@"OK"
		style:UIAlertActionStyleCancel
		handler:nil
	]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)pushFieldsTableView {
	UITableViewController *fieldsTableViewController = [UITableViewController new];
	fieldsTableViewController.tableView.dataSource = self;
	fieldsTableViewController.tableView.delegate = self;
	[self.navigationController pushViewController:fieldsTableViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.tableView) {
		NSArray *rowInfo = filteredCells[indexPath.row];
		if ([rowInfo isKindOfClass:[NSArray class]] && [rowInfo[0] isEqualToString:@"Text"] && rowInfo.count >= 3 && [rowInfo[2] isKindOfClass:[NSString class]]) {
			SEL selector = NSSelectorFromString(rowInfo[2]);
			if (rowInfo.count >= 4 && [NSStringFromSelector(selector) hasSuffix:@":"]) {
				((void(*)(PackageDetailsController *, SEL, id))class_getMethodImplementation(self.class, selector))(self, selector, rowInfo[3]);
			}
			else {
				((void(*)(PackageDetailsController *, SEL))class_getMethodImplementation(self.class, selector))(self, selector);
			}
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return ((tableView != self.tableView) || [filteredCells[indexPath.row] isKindOfClass:[NSDictionary class]]) && (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if ((tableView != self.tableView) && (action == @selector(copy:))){
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		[[UIPasteboard generalPasteboard] setString:cell.detailTextLabel.text];
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
	return ((tableView != self.tableView) || [filteredCells[indexPath.row] isKindOfClass:[NSDictionary class]]);
}

- (void)database:(Database *)database didRemoveSource:(Source *)source {
	if (source == _package.source) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

- (void)sourceDidStartRefreshing:(Source *)source {
	if (source == _package.source) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

@end
