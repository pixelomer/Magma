#import "DownloadsController.h"
#import "DownloadManager.h"
#import "OngoingDownloadCell.h"

@implementation DownloadsController

- (void)viewDidLoad {
	[super viewDidLoad];
	cells = [DownloadManager.sharedInstance allTaskIdentifiers].mutableCopy;
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
		BOOL shouldInsert = cells.count;
		[cells addObject:taskID];
		__block NSArray *indexPaths = @[[NSIndexPath indexPathForRow:(cells.count-1) inSection:0]];
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
		NSInteger index = [cells indexOfObject:taskID];
		NSString *error = notif.userInfo[@"error"];
		if (index != NSNotFound) {
			__block NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
			if ([error isKindOfClass:[NSString class]]) {
				[cells replaceObjectAtIndex:index withObject:@[error, notif.userInfo[@"packageName"], notif.userInfo[@"taskID"]]];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
					indexPaths = nil;
				});
			}
			else {
				[cells removeObjectAtIndex:index];
				BOOL shouldDelete = cells.count;
				dispatch_async(dispatch_get_main_queue(), ^{
					if (shouldDelete) {
						[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
					}
					else {
						[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
					}
					indexPaths = nil;
				});
			}
		}
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return !section * (cells.count ?: 1);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!indexPath.section && [cells[indexPath.row] isKindOfClass:[NSArray class]]) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		__block NSArray *details = cells[indexPath.row];
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download Failed" message:(details[0] ?: @"An unknown error occurred.") preferredStyle:UIAlertControllerStyleAlert];
		/*
		[alert addAction:[UIAlertAction
			actionWithTitle:@"Yes"
			style:UIAlertActionStyleDefault
			handler:^(UIAlertAction * _Nonnull action) {
				NSInteger index = [self->cells indexOfObjectIdenticalTo:details];
				if (index != NSNotFound) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self->cells removeObjectAtIndex:index];
						NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
						if (self->cells.count) {
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
				NSInteger index = [self->cells indexOfObjectIdenticalTo:details];
				if (index != NSNotFound) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self->cells removeObjectAtIndex:index];
						NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
						if (self->cells.count) {
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
	else if (indexPath.section == 1) {
		
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section ? @"Local Packages" : @"Ongoing Downloads";
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (!indexPath.section) {
		if (cells.count > 0) {
			if ([cells[indexPath.row] isKindOfClass:[NSNumber class]]) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"ongoing"] ?: [[OngoingDownloadCell alloc] initWithReuseIdentifier:@"ongoing"];
				[(OngoingDownloadCell *)cell setIdentifier:[(NSNumber *)cells[indexPath.row] unsignedIntegerValue]];
			}
			else if ([cells[indexPath.row] isKindOfClass:[NSArray class]]) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"failed"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"failed"];
				cell.detailTextLabel.text = @"Download failed. Tap for details.";
				cell.textLabel.text = [(NSArray *)cells[indexPath.row] objectAtIndex:1];
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
		cell = [tableView dequeueReusableCellWithIdentifier:@"package"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"package"];
		cell.textLabel.text = [NSString stringWithFormat:@"Package %d", (int)(indexPath.row + 1)];
	}
	return cell;
}

@end
