#import "PackagesController.h"
#import "Source.h"
#import "Package.h"
#import "PackageCell.h"

@implementation PackagesController

+ (NSArray *)latestSortedPackagesFromPackageArray:(NSArray *)array {
	NSMutableDictionary *filteredPackages = [NSMutableDictionary new];
	for (Package *package in array) {
		NSString *ID = package.package;
		if (!filteredPackages[ID] || ([package compare:filteredPackages[ID]] == NSOrderedDescending)) {
			filteredPackages[ID] = package;
		}
	}
	return [filteredPackages.allValues sortedArrayUsingSelector:@selector(compare:)];
}

- (instancetype)initWithFilters:(NSDictionary *)customFilters {
	if (self = [super init]) {
		NSMutableDictionary *filters = @{
			@"showObsoletePackages" : @NO, // Packages with cydia::obsolete tag
			@"showSystemPackages" : @NO,   // Packages with role::cydia tag
			@"includeRemotePackages" : @YES,
			@"includeLocalPackages" : @NO,
		//	@"source" : packageSource,
		//	@"section" : @"section"
		}.mutableCopy;
		for (NSString *key in customFilters) filters[key] = customFilters[key];
		NSMutableArray<Package *> *filteredPackages = [NSMutableArray new];
		if ([(NSNumber *)filters[@"includeRemotePackages"] boolValue]) {
			if (filters[@"source"]) {
				if (filters[@"section"]) {
					[filteredPackages addObjectsFromArray:[(Source *)filters[@"source"] sections][filters[@"section"]]];
				}
				else {
					[filteredPackages addObjectsFromArray:[(Source *)filters[@"source"] packages]];
				}
			}
			else {
				if (filters[@"section"]) {
					// Logic needed
				}
				else {
					[filteredPackages addObjectsFromArray:Database.sharedInstance.sortedRemotePackages];
				}
			}
		}
		if ([(NSNumber *)filters[@"includeLocalPackages"] boolValue]) {
			if (filters[@"section"]) {
				// Logic needed
			}
			else {
				[filteredPackages addObjectsFromArray:Database.sharedInstance.sortedLocalPackages];
			}
		}
		filteredPackages = [self.class latestSortedPackagesFromPackageArray:filteredPackages].mutableCopy;
		if (![(NSNumber *)filters[@"showSystemPackages"] boolValue]) {
			for (NSInteger i = filteredPackages.count-1; i >= 0; i--) {
				Package *package = filteredPackages[i];
				if ([package.tags containsObject:@"role::cydia"]) {
					[filteredPackages removeObjectAtIndex:i];
				}
			}
		}
		if (![(NSNumber *)filters[@"showObsoletePackages"] boolValue]) {
			for (NSInteger i = filteredPackages.count-1; i >= 0; i--) {
				Package *package = filteredPackages[i];
				if ([package.tags containsObject:@"cydia:obsolete"]) {
					[filteredPackages removeObjectAtIndex:i];
				}
			}
		}
		_packages = filteredPackages.copy;
		return self;
	}
	return nil;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PackageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"package"] ?: [[PackageCell alloc] initWithReuseIdentifier:@"package"];
	cell.package = _packages[indexPath.row];
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _packages.count;
}

@end