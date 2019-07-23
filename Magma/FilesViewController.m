//
//  FilesViewController.m
//  Magma
//
//  Created by PixelOmer on 19.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "FilesViewController.h"
#import "AssetExtensions.h"
#import "SpinnerViewController.h"
#import <objc/runtime.h>

@implementation FilesViewController

static UIColor *newFileColor;

// Example:
// @{ @"doc" : @[@"Word file", @"WordFileController", @"initWithWordFile:"] }
static NSDictionary<NSString *, NSArray *> *filetypes;

// Example:
// @{ @"ar" : @[@"NSData", @"unarchiveFileAtPath:toDirectoryAtPath:"] }
static NSDictionary<NSString *, NSArray *> *archiveTypes;

+ (void)load {
	if (self == [FilesViewController class]) {
		newFileColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.15];
		NSMutableDictionary *mutableFileTypes = @{
			@"txt" : @[@"Text File", @"TextFileViewController", @"initWithPath:"],
			@"h" : @[@"Header File", @"SourceCodeFileController", @"initWithPath:"]
		}.mutableCopy;
		
		// Manual pages
		NSArray *sharedArray = @[@"Manual Page", @"ManpageViewController", @"initWithPath:"];
		for (int i = 1; i <= 9; i++) mutableFileTypes[[NSString stringWithFormat:@"%d", i]] = sharedArray;
		
		// HTML files
		sharedArray = @[@"HTML File", @"HTMLViewController", @"initWithPath:"];
		for (char c = 'a'; c <= 'z'; c++) mutableFileTypes[[NSString stringWithFormat:@"%chtml", c]] = sharedArray;
		mutableFileTypes[@"htm"] = sharedArray;
		mutableFileTypes[@"html"] = sharedArray;
		sharedArray = @[@"HTML Application", @"HTMLViewController", @"initWithPath:"];
		mutableFileTypes[@"hta"] = sharedArray;
		
		// Archive types
		NSMutableDictionary *mutableArchiveTypes = [NSMutableDictionary new];
		sharedArray = @[
			@[@"gz", @"Gzip Archive", @"NSData", @"gunzipFile:toFile:"],
			@[@"bz2", @"Bzip2 Archive", @"NSData", @"bunzipFile:toFile:"],
			@[@"xz", @"XZ Archive", @"NSData", @"extractXZFileAtPath:toFileAtPath:"],
			@[@"tar", @"Tar Archive", @"NSFileManager", @"extractTarArchiveAtPath:toPath:"],
			@[@"a", @"Archive", @"NSData", @"unarchiveFileAtPath:toDirectoryAtPath:"],
			@[@"lzma", @"LZMA Archive", @"NSData", @"extractLZMAFileAtPath:toFileAtPath:"]
		];
		for (NSArray *array in sharedArray) {
			mutableFileTypes[array[0]] = @[array[1], NSNull.null, NSNull.null];
			mutableArchiveTypes[array[0]] = @[array[2], array[3]];
		}
		
		// Assign the copies of mutable variables to the static variables
		filetypes = mutableFileTypes.copy;
		archiveTypes = mutableArchiveTypes.copy;
	}
}

- (void)reloadFiles:(UIRefreshControl *)sender {
	__block UIRefreshControl *_refreshControl = refreshControl;
	__block NSString *_newFile = newFile.copy;
	newFile = nil;
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
			newFilesWithTypes[filename] = @[@(!!isDir), subtitle, @(!![_newFile isEqualToString:filename])];
		}
		self.files = newFilesWithTypes.copy;
		__block UIRefreshControl *__refreshControl = _refreshControl;
		_refreshControl = nil;
		dispatch_async(dispatch_get_main_queue(), ^{
			if (__refreshControl) {
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
				[__refreshControl endRefreshing];
				__refreshControl = nil;
			}
		});
		_newFile = nil;
	});
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
	NSString *ext = filename.pathExtension.lowercaseString;
	NSArray *fileTypeDetails = filetypes[ext];
	if ([cellInfo[0] boolValue]) {
		FilesViewController *vc = [[FilesViewController alloc] initWithPath:newPath];
		if (vc) {
			[self.navigationController pushViewController:vc animated:YES];
			return;
		}
	}
	else if ([fileTypeDetails[1] isKindOfClass:[NSString class]]) {
		Class cls = NSClassFromString(fileTypeDetails[1]);
		SEL selector = NSSelectorFromString(fileTypeDetails[2]);
		if (cls && selector) {
			UIViewController *vc = ((UIViewController *(*)(UIViewController *, SEL, NSString *))(method_getImplementation(class_getInstanceMethod(cls, selector))))([cls alloc], selector, newPath);
			if (vc) {
				vc.title = filename;
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
			// Developer error, not implemented
		}
	}
	else if ([fileTypeDetails[1] isKindOfClass:[NSNull class]] && (fileTypeDetails = archiveTypes[ext])) {
		// Archive type
		Class cls = NSClassFromString(fileTypeDetails[0]);
		SEL selector = NSSelectorFromString(fileTypeDetails[1]);
		BOOL(*extract)(Class, SEL, NSString *, NSString *);
		extract = (BOOL(*)(Class, SEL, NSString *, NSString *))(method_getImplementation(class_getClassMethod(cls, selector)));
		__block SpinnerViewController *spinnerVC = [SpinnerViewController new];
		spinnerVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
		newFile = newPath.lastPathComponent.stringByDeletingPathExtension;
		[self presentViewController:spinnerVC animated:NO completion:^{
			__block SpinnerViewController *_spinnerVC = spinnerVC;
			spinnerVC = nil;
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
				BOOL success = extract(cls, selector, newPath, newPath.stringByDeletingPathExtension);
				__block SpinnerViewController *__spinnerVC = _spinnerVC;
				_spinnerVC = nil;
				dispatch_async(dispatch_get_main_queue(), ^{
					if (success) {
						[self reloadFiles:nil];
					}
					else {
						NSLog(@"Error");
					}
					[__spinnerVC dismissViewControllerAnimated:NO completion:nil];
				});
			});
		}];
	}
	else {
		// Unknown file type
	}
	// Error presenting VC
	[tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
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
	if ([(NSNumber *)cellInfo[2] boolValue]) {
		cell.backgroundColor = newFileColor;
	}
	else {
		cell.backgroundColor = [UIColor clearColor];
	}
	cell.textLabel.backgroundColor = cell.detailTextLabel.backgroundColor = [UIColor clearColor];
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
