#import "DownloadsController.h"
#import "DownloadManager.h"
#import "UIImage+ResizeImage.h"
#import "OngoingDownloadCell.h"

@implementation DownloadsController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self reloadLocalPackages];
	downloadCells = [DownloadManager.sharedInstance allTaskIdentifiers].mutableCopy;
	[NSNotificationCenter.defaultCenter
		addObserver:self
		selector:@selector(didReceiveDownloadNotification:)
		name:nil
		object:DownloadManager.sharedInstance
	];
	self.title = @"Downloads";
}

- (void)didReceiveDownloadNotification:(NSNotification *)notif {
	NSNumber *taskID = notif.userInfo[@"taskID"];
	if ([notif.name isEqualToString:DownloadDidStartNotification]) {
		BOOL shouldInsert = downloadCells.count;
		[downloadCells addObject:taskID];
		__block NSArray *indexPaths = @[[NSIndexPath indexPathForRow:(downloadCells.count-1) inSection:0]];
		dispatch_async(dispatch_get_main_queue(), ^{
			if (shouldInsert) {
				[self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
			}
			else {
				[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
			}
			indexPaths = nil;
		});
	}
	else if ([notif.name isEqualToString:DownloadDidCompleteNotification]) {
		NSInteger index = [downloadCells indexOfObject:taskID];
		NSString *error = notif.userInfo[@"error"];
		if (index != NSNotFound) {
			__block NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
			if ([error isKindOfClass:[NSString class]]) {
				[downloadCells replaceObjectAtIndex:index withObject:@[error, notif.userInfo[@"packageName"]]];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
					indexPaths = nil;
				});
			}
			else {
				[downloadCells removeObjectAtIndex:index];
				BOOL shouldDelete = downloadCells.count;
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.tableView beginUpdates];
					if (shouldDelete) {
						[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
					}
					else {
						[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
					}
					indexPaths = nil;
					[self reloadLocalPackages];
					[self.tableView endUpdates];
				});
			}
		}
	}
}

- (void)reloadLocalPackages {
	NSError *error;
	NSMutableArray<NSString *> *allFiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:DownloadManager.sharedInstance.downloadsPath error:&error].mutableCopy;
	for (NSInteger i = 0; i < allFiles.count; i++) {
		NSString *filePath = [DownloadManager.sharedInstance.downloadsPath stringByAppendingPathComponent:allFiles[i]];
		BOOL isDir;
		if (![NSFileManager.defaultManager fileExistsAtPath:filePath isDirectory:&isDir] || !isDir) {
			[NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
			[allFiles removeObjectAtIndex:i];
			i--;
		}
	}
	[allFiles sortUsingSelector:@selector(compare:)];
	for (NSInteger i = 0; i < allFiles.count; i++) {
		NSMutableArray *components = [allFiles[i] componentsSeparatedByString:@"_"].mutableCopy;
		NSString *name = components[0];
		[components removeObjectAtIndex:0];
		NSString *version = [components componentsJoinedByString:@"_"]; // It's illegal to have an underscore in a debian package version but everything is possible
		allFiles[i] = (id)@[name, version];
	}
	self->packageCells = allFiles.copy;
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return !section ? (downloadCells.count ?: 1) : packageCells.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!indexPath.section && [downloadCells[indexPath.row] isKindOfClass:[NSArray class]]) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		__block NSArray *details = downloadCells[indexPath.row];
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download Failed" message:(details[0] ?: @"An unknown error occurred.") preferredStyle:UIAlertControllerStyleAlert];
		/*
		[alert addAction:[UIAlertAction
			actionWithTitle:@"Yes"
			style:UIAlertActionStyleDefault
			handler:^(UIAlertAction * _Nonnull action) {
				NSInteger index = [self->downloadCells indexOfObjectIdenticalTo:details];
				if (index != NSNotFound) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self->downloadCells removeObjectAtIndex:index];
						NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
						if (self->downloadCells.count) {
							[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
						}
						else {
							[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
						}
						[DownloadManager.sharedInstance retryDownloadWithIdentifier:[(NSNumber *)details[2] unsignedIntegerValue]];
						details = nil;
					});
				}
				else {
					details = nil;
				}
			}
		]];
		*/
		[alert addAction:[UIAlertAction
			actionWithTitle:/* @"No" */ @"OK"
			style:UIAlertActionStyleCancel
			handler:^(UIAlertAction * _Nonnull action) {
				NSInteger index = [self->downloadCells indexOfObjectIdenticalTo:details];
				if (index != NSNotFound) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self->downloadCells removeObjectAtIndex:index];
						NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
						if (self->downloadCells.count) {
							[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
						}
						else {
							[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
						}
					});
				}
				details = nil;
			}
		]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	else if (indexPath.section) {
		
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section ? @"Local Packages" : @"Ongoing Downloads";
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (!indexPath.section) {
		if (downloadCells.count > 0) {
			if ([downloadCells[indexPath.row] isKindOfClass:[NSNumber class]]) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"ongoing"] ?: [[OngoingDownloadCell alloc] initWithReuseIdentifier:@"ongoing"];
				[(OngoingDownloadCell *)cell setIdentifier:[(NSNumber *)downloadCells[indexPath.row] unsignedIntegerValue]];
			}
			else if ([downloadCells[indexPath.row] isKindOfClass:[NSArray class]]) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"failed"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"failed"];
				cell.detailTextLabel.text = @"Download failed. Tap for details.";
				cell.textLabel.text = [(NSArray *)downloadCells[indexPath.row] objectAtIndex:1];
			}
		}
		else {
			if (!(cell = [tableView dequeueReusableCellWithIdentifier:@"noOngoing"])) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noOngoing"];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.textLabel.text = @"No ongoing downloads.";
			}
		}
	}
	else {
		NSArray *folderComponents = packageCells[indexPath.row];
		if (!(cell = [tableView dequeueReusableCellWithIdentifier:@"package"])) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"package"];
			cell.imageView.image = [[UIImage imageNamed:@"Folder"] resizedImageOfSize:CGSizeMake(30, 30)];
			cell.separatorInset = UIEdgeInsetsZero;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		cell.textLabel.text = folderComponents[0];
		cell.detailTextLabel.text = folderComponents[1];
	}
	return cell;
}

@end
