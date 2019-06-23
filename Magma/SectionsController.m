#import "SectionsController.h"
#import "PackageCell.h"
#import "SectionPackagesController.h"
#import "Source.h"

@implementation SectionsController

- (instancetype)initWithSource:(Source *)source {
	if (source && !source.isRefreshing && (self = [super init])) {
		_source = source;
		sections = [_source.sections.allKeys sortedArrayUsingSelector:@selector(compare:)];
		return self;
	}
	return nil;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"section"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"section"];
	cell.textLabel.text = sections[indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return sections.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	SectionPackagesController *vc = [[SectionPackagesController alloc] initWithSection:sections[indexPath.row] inSource:_source];
	if (vc) {
		[self.navigationController pushViewController:vc animated:YES];
	}
	else {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

@end