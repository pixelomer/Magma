//
//  FilesViewController.m
//  Magma
//
//  Created by PixelOmer on 19.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "FilesViewController.h"

@implementation FilesViewController

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
				if (isDir) subtitle = [NSString stringWithFormat:@"%lu file(s)", (unsigned long)[NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil].count];
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
	if ([cellInfo[0] boolValue]) {
		FilesViewController *vc = [[FilesViewController alloc] initWithPath:[_path stringByAppendingPathComponent:filename]];
		if (!vc) [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
		else [self.navigationController pushViewController:vc animated:YES];
	}
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
