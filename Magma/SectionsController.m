#import "SectionsController.h"
#import "PackageCell.h"
#import "SectionPackagesController.h"
#import "Source.h"
#import "Database.h"
#import "Package.h"

@implementation SectionsController

- (instancetype)init {
	return [self initWithSource:nil];
}

- (instancetype)initWithSource:(Source *)source {
	if (self = [super init]) {
		if (source && !source.isRefreshing) {
			_source = source;
			self.title = source.origin;
			NSMutableDictionary *mSections = [NSMutableDictionary new];
			NSDictionary<NSString *, NSArray *> *sourceSections = _source.sections.copy;
			for (NSString *sectionName in sourceSections) {
				mSections[sectionName] = @([Package latestSortedPackagesFromPackageArray:sourceSections[sectionName]].count);
			}
			sections = [mSections copy];
		}
		else if (!Database.sharedInstance.isRefreshing) {
			NSMutableDictionary<NSString *, NSNumber *> *mSections = [NSMutableDictionary new];
			self.title = @"All Sections";
			for (Source *sourceFromDatabase in Database.sharedInstance.sources.copy) {
				NSDictionary<NSString *, NSArray *> *sourceSections = sourceFromDatabase.sections.copy;
				for (NSString *section in sourceSections) {
					mSections[section] = @(mSections[section].integerValue + [Package latestSortedPackagesFromPackageArray:sourceSections[section]].count);
				}
			}
			sections = [mSections copy];
		}
		else return nil;
		totalPackageCount = @(0);
		for (NSNumber *packageCount in sections.allValues) {
			totalPackageCount = @(totalPackageCount.integerValue + packageCount.integerValue);
		}
		sortedSections = [sections.allKeys sortedArrayUsingSelector:@selector(compare:)];
		return self;
	}
	return nil;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"section"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"section"];
	cell.textLabel.text = indexPath.section ? sortedSections[indexPath.row] : @"All Packages";
	cell.detailTextLabel.text = (indexPath.section ? sections[sortedSections[indexPath.row]] : totalPackageCount).stringValue;
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
	NSString *title = (indexPath.section ? sortedSections[indexPath.row] : @"All Packages");
	SectionPackagesController *vc = [[SectionPackagesController alloc] initWithSection:(indexPath.section ? sortedSections[indexPath.row] : nil) inSource:_source];
	vc.title = title;
	[self pushViewController:vc animated:YES];
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
