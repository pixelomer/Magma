#import "DownloadsController.h"
#import "DownloadManager.h"
#import "OngoingDownloadCell.h"

@implementation DownloadsController

- (void)viewDidLoad {
	[super viewDidLoad];
	downloadIdentifiers = [DownloadManager.sharedInstance allTaskIdentifiers].mutableCopy;
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
		BOOL shouldInsert = downloadIdentifiers.count;
		[downloadIdentifiers addObject:taskID];
		__block NSArray *indexPaths = @[[NSIndexPath indexPathForRow:(downloadIdentifiers.count-1) inSection:0]];
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
		NSInteger index = [downloadIdentifiers indexOfObject:taskID];
		if (index != NSNotFound) {
			[downloadIdentifiers removeObjectAtIndex:index];
			BOOL shouldDelete = downloadIdentifiers.count;
			__block NSArray *indexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return !section * (downloadIdentifiers.count ?: 1);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section ? @"Local Packages" : @"Ongoing Downloads";
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (!indexPath.section) {
		if (downloadIdentifiers.count > 0) {
			cell = [tableView dequeueReusableCellWithIdentifier:@"ongoing"] ?: [[OngoingDownloadCell alloc] initWithReuseIdentifier:@"ongoing"];
			[(OngoingDownloadCell *)cell setIdentifier:downloadIdentifiers[indexPath.row].unsignedIntegerValue];
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
