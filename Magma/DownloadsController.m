#import "DownloadsController.h"

@implementation DownloadsController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Downloads";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (section * 4) + 1;
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
		cell = [tableView dequeueReusableCellWithIdentifier:@"ongoing"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ongoing"];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.text = @"No ongoing downloads.";
	}
	else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"package"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"package"];
		cell.textLabel.text = [NSString stringWithFormat:@"Package %d", (int)(indexPath.row + 1)];
	}
	return cell;
}

@end
