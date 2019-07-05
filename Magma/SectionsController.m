#import "SectionsController.h"
#import "PackageCell.h"
#import "SectionPackagesController.h"
#import "Source.h"

@implementation SectionsController

- (instancetype)initWithSource:(Source *)source {
	if (source && !source.isRefreshing && (self = [super init])) {
		_source = source;
		self.title = source.origin;
		sections = [_source.sections.allKeys sortedArrayUsingSelector:@selector(compare:)];
		return self;
	}
	return nil;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"section"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"section"];
	cell.textLabel.text = indexPath.section ? sections[indexPath.row] : @"All Packages";
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section ? sections.count : 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *title = (indexPath.section ? sections[indexPath.row] : @"All Packages");
	SectionPackagesController *vc = [[SectionPackagesController alloc] initWithSection:(indexPath.section ? sections[indexPath.row] : nil) inSource:_source];
	vc.title = title;
	if (vc) {
		[self.navigationController pushViewController:vc animated:YES];
	}
	else {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section ? @"Sections" : nil;
}

@end
