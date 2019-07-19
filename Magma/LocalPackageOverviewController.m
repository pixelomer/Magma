//
//  LocalPackageOverviewController.m
//  Magma
//
//  Created by PixelOmer on 18.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "LocalPackageOverviewController.h"
#import "DownloadManager.h"
#import "TextViewCell.h"
#import "DPKGParser.h"

@implementation LocalPackageOverviewController

static NSArray *cells;

+ (void)load {
	if (self == [LocalPackageOverviewController class]) {
		/* Cell format
		 * @[image (not null), tint_color (nullable)]
		 */
		cells = @[
			// First cell is the description cell. It is not in this array.
			@[[UIImage imageNamed:@"Folder"], [UIColor colorWithRed:0.968 green:0.772 blue:0.192 alpha:1.0], @"FilesViewController", @"initWithPath:", @"Browse Files"]
		];
	}
}

- (instancetype)initWithPackageName:(NSString *)packageName {
	NSString *fullPath = [DownloadManager.sharedInstance.downloadsPath stringByAppendingPathComponent:packageName];
	BOOL isDir;
	if (![NSFileManager.defaultManager fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir) return nil;
	if (self = [super init]) {
		if (!(_controlFile = [DPKGParser parseFileAtPath:[fullPath stringByAppendingPathComponent:@"DEBIAN/control"] error:nil].firstObject)) return nil;
		if (!_controlFile[@"description"]) description = @"(No description available)";
		else {
			NSMutableArray *components = [_controlFile[@"description"] componentsSeparatedByString:@"\n"].mutableCopy;
			if (components.count <= 1) description = components[0];
			else if (components.count > 1) {
				[components removeObjectAtIndex:0];
				description = [[components componentsJoinedByString:@"\n"] stringByReplacingOccurrencesOfString:@"\n.\n" withString:@"\n\n"];
			}
		}
		self.title = [packageName componentsSeparatedByString:@"_"].firstObject;
		_packagePath = fullPath;
	}
	return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return cells.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!indexPath.row) {
		TextViewCell *descriptionCell = [tableView dequeueReusableCellWithIdentifier:@"textView"] ?: [[TextViewCell alloc] initWithReuseIdentifier:@"textView"];
		descriptionCell.textViewText = description;
		descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
		return descriptionCell;
	}
	else {
		NSArray *cellInfo = cells[indexPath.row-1];
		UITableViewCell *regularCell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
		regularCell.imageView.image = [cellInfo[0] resizedImageOfSize:CGSizeMake(24, 24)];
		if ([cellInfo[1] isKindOfClass:[UIColor class]]) {
			regularCell.imageView.image = [regularCell.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			regularCell.imageView.tintColor = cellInfo[1];
		}
		regularCell.textLabel.text = cellInfo[4];
		regularCell.separatorInset = UIEdgeInsetsZero;
		regularCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return regularCell;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row) {
		NSArray *cellInfo = cells[indexPath.row-1];
		__kindof UIViewController *viewController = [NSClassFromString(cellInfo[2]) alloc];
		SEL selector = NSSelectorFromString(cellInfo[3]);
		NSMethodSignature *signature = [viewController methodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		invocation.target = viewController;
		invocation.selector = selector;
		NSArray *possibleArguments = @[
			_packagePath
		];
		for (int i = 2; ((i < invocation.methodSignature.numberOfArguments) && ((i-2) < possibleArguments.count)); i++) {
			id object = possibleArguments[i-2];
			[invocation setArgument:&object atIndex:i];
		}
		[invocation invoke];
		[invocation getReturnValue:&viewController];
		if (viewController) {
			[self.navigationController pushViewController:viewController animated:YES];
		}
		else {
			[self.tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
		}
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

@end
