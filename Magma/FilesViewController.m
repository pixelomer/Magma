//
//  FilesViewController.m
//  Magma
//
//  Created by PixelOmer on 19.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "FilesViewController.h"
#import <objc/runtime.h>

@implementation FilesViewController

// Example:
// { @".doc" : @[@"Word file", @"WordFileController", @"initWithWordFile:"] }
static NSDictionary<NSString *, NSArray *> *filetypes;

+ (void)load {
	if (self == [FilesViewController class]) {
		NSMutableDictionary *mutableFileTypes = @{
			
		}.mutableCopy;
		NSArray *manpageArray = @[@"Manual Page", @"ManpageViewController", @"initWithPath:"];
		for (int i = 1; i <= 9; i++) mutableFileTypes[[NSString stringWithFormat:@"%d", i]] = manpageArray;
		filetypes = mutableFileTypes.copy;
	}
}

- (void)reloadFiles:(UIRefreshControl *)sender {
	if (sender == refreshControl || (!sender && !filenames && !fileDetails)) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			NSArray *newFiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:self.path error:nil];
			NSMutableDictionary *newFilesWithTypes = [NSMutableDictionary new];
			for (NSString *filename in newFiles) {
				if ([filename isEqualToString:@".magma"]) continue;
				NSString *path = [self.path stringByAppendingPathComponent:filename];
				BOOL isDir;
				if (![NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]) continue;
				NSString *subtitle = @"";
				if (isDir) {
					subtitle = [NSString stringWithFormat:@"%lu file(s)", (unsigned long)[NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil].count];
				}
				else if (filetypes[filename.pathExtension.lowercaseString]) {
					subtitle = filetypes[filename.pathExtension.lowercaseString][0];
				}
				else subtitle = @"Unknown Type";
				newFilesWithTypes[filename] = @[@(!!isDir), subtitle];
			}
			self.files = newFilesWithTypes.copy;
			dispatch_async(dispatch_get_main_queue(), ^{
				if (sender) {
					[self.tableView reloadData];
					[sender endRefreshing];
				}
			});
		});
	}
}

- (void)setFiles:(NSDictionary *)files {
	NSArray *sortedKeys = [files.allKeys sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *sortedValues = [NSMutableArray new];
	for (NSInteger i = 0; i < sortedKeys.count; i++) {
		sortedValues[i] = files[sortedKeys[i]];
	}
	filenames = sortedKeys;
	fileDetails = sortedValues.copy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadFiles:nil];
	refreshControl = [UIRefreshControl new];
	if (@available(iOS 10.0, *)) {
		self.tableView.refreshControl = refreshControl;
	}
	else {
		[self.view addSubview:refreshControl];
	}
	[refreshControl addTarget:self action:@selector(reloadFiles:) forControlEvents:UIControlEventValueChanged];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return filenames.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *filename = filenames[indexPath.row];
	NSArray *cellInfo = fileDetails[indexPath.row];
	NSString *newPath = [_path stringByAppendingPathComponent:filename];
	NSArray *fileTypeDetails = filetypes[filename.pathExtension.lowercaseString];
	if ([cellInfo[0] boolValue]) {
		FilesViewController *vc = [[FilesViewController alloc] initWithPath:newPath];
		if (!vc) [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
		else [self.navigationController pushViewController:vc animated:YES];
		return;
	}
	else if ([fileTypeDetails[1] isKindOfClass:[NSString class]]) {
		Class cls = NSClassFromString(fileTypeDetails[1]);
		SEL selector = NSSelectorFromString(fileTypeDetails[2]);
		UIViewController *vc = ((UIViewController *(*)(UIViewController *, SEL, NSString *))(method_getImplementation(class_getInstanceMethod(cls, selector))))([cls alloc], selector, newPath);
		if (vc) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
			if (navController) {
				navController.modalPresentationStyle = UIModalPresentationFullScreen;
				navController.view.backgroundColor = [UIColor whiteColor];
				UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissInfoViewController:)];
				objc_setAssociatedObject(doneButton, @selector(dismissInfoViewController:), navController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
				vc.navigationItem.leftBarButtonItem = doneButton;
				[self presentViewController:navController animated:YES completion:nil];
				return;
			}
		}
	}
	else {
		// Unknown file type
	}
	// Error presenting VC
}

- (void)dismissInfoViewController:(UIBarButtonItem *)sender {
	UINavigationController *navController = objc_getAssociatedObject(sender, _cmd);
	objc_setAssociatedObject(sender, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[navController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (!(cell = [tableView dequeueReusableCellWithIdentifier:@"cell"])) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
	}
	NSArray *cellInfo = fileDetails[indexPath.row];
	cell.textLabel.text = filenames[indexPath.row];
	cell.detailTextLabel.text = cellInfo[1];
	if ([(NSNumber *)cellInfo[0] boolValue]) {
		cell.imageView.image = [UIImage folderIcon];
		cell.imageView.tintColor = [UIColor folderTintColor];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else {
		cell.imageView.image = [UIImage fileIcon];
		cell.imageView.tintColor = nil;
		cell.accessoryType = UITableViewCellAccessoryDetailButton;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (instancetype)initWithPath:(NSString *)path {
	BOOL isDir;
	if (![NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir] || !isDir) return nil;
	if ((self = [super init])) {
		self.title = path.lastPathComponent;
		_path = path;
	}
	return self;
}

@end
