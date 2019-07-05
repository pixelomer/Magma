#import "SectionsController.h"
#import "PackageCell.h"
#import "SectionPackagesController.h"
#import "Source.h"
#import "Database.h"

@implementation SectionsController

- (instancetype)init {
	return [self initWithSource:nil];
}

- (instancetype)initWithSource:(Source *)source {
	if (self = [super init]) {
		if (source && !source.isRefreshing) {
			_source = source;
			self.title = source.origin;
			sections = [_source.sections.allKeys sortedArrayUsingSelector:@selector(compare:)];
		}
		else if (!Database.sharedInstance.isRefreshing) {
			NSMutableArray *mSections = [NSMutableArray new];
			self.title = @"All Sections";
			for (Source *sourceFromDatabase in Database.sharedInstance.sources.copy) {
				for (NSString *section in sourceFromDatabase.sections.allKeys) {
					if (![mSections containsObject:section]) {
						[mSections addObject:section];
					}
				}
			}
			sections = [mSections sortedArrayUsingSelector:@selector(compare:)];
		}
		else return nil;
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

- (void)database:(Database *)database didRemoveSource:(Source *)source {
	if (_source == source) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

- (void)sourceDidStartRefreshing:(Source *)source {
	if (_source == source) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

- (void)databaseDidStart {
	if (!_source) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

@end
