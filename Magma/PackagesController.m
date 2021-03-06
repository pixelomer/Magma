#import "PackagesController.h"
#import "Source.h"
#import "Package.h"
#import "PackageCell.h"
#import "PackageDetailsController.h"

@implementation PackagesController

- (instancetype)init {
	return [self initWithFilters:nil];
}

- (instancetype)initWithFilters:(NSDictionary *)customFilters {
	if (self = [super init]) {
		NSMutableDictionary *filters = @{
		//	@"source" : packageSource,
		//	@"section" : @"section"
		}.mutableCopy;
		for (NSString *key in customFilters) filters[key] = customFilters[key];
		NSMutableArray<Package *> *filteredPackages = [NSMutableArray new];
		if ([filters[@"source"] isKindOfClass:[Source class]]) {
			if ([filters[@"section"] isKindOfClass:[NSString class]]) {
				[filteredPackages addObjectsFromArray:[(Source *)filters[@"source"] sections][filters[@"section"]]];
			}
			else {
				[filteredPackages addObjectsFromArray:[(Source *)filters[@"source"] packages]];
			}
		}
		else {
			if ([filters[@"section"] isKindOfClass:[NSString class]]) {
				// UNTESTED
				[filteredPackages addObjectsFromArray:[Database.sharedInstance.sortedRemotePackages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"section == %@", filters[@"section"]]]];
			}
			else {
				[filteredPackages addObjectsFromArray:Database.sharedInstance.sortedRemotePackages];
			}
		}
		filteredPackages = [Package latestSortedPackagesFromPackageArray:filteredPackages].mutableCopy;
		_packages = filteredPackages.copy;
		return self;
	}
	return nil;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PackageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"package"] ?: [[PackageCell alloc] initWithReuseIdentifier:@"package"];
	cell.package = _packages[indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _packages.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Package *package = _packages[indexPath.row];
	PackageDetailsController *vc = [[PackageDetailsController alloc] initWithPackage:package];
	[self pushViewController:vc animated:YES];
}

@end
