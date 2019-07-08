#import "PackageSearchViewController.h"
#import "PackageCell.h"
#import "PackageDetailsController.h"
#import "Package.h"

@implementation PackageSearchViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Search";
}

- (UITableView *)setupTableView {
	self.dataSource = self;
	self.delegate = self;
	_searchBar = [UISearchBar new];
    _searchBar.placeholder = @"Search Packages";
	_searchBar.delegate = self;
	UITableView *tableView;
	if (@available(iOS 11.0, *)) {
		tableView = [UITableView new];
		tableView.translatesAutoresizingMaskIntoConstraints = NO;
		_searchBar.translatesAutoresizingMaskIntoConstraints = NO;
		[self.view addSubview:_searchBar];
		[self.view addSubview:tableView];
		NSDictionary *views = @{ @"searchBar" : _searchBar, @"tableView" : tableView };
		[self.view addConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"V:|[searchBar][tableView]|"
			options:NSLayoutFormatAlignAllCenterX
			metrics:nil
			views:views
		]];
		for (UIView *view in views.allValues) {
			[self.view addConstraints:[NSLayoutConstraint
				constraintsWithVisualFormat:@"H:|[view]|"
				options:NSLayoutFormatAlignAllCenterX
				metrics:nil
				views:@{ @"view" : view }
			]];
		}
	}
	else {
		tableView = [super setupTableView];
		self.title = nil;
		self.navigationItem.titleView = _searchBar;
	}
	return tableView;
}

- (void)databaseDidLoad:(Database *)database {
	[super databaseDidLoad:database];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return packages.count;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PackageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"package"] ?: [[PackageCell alloc] initWithReuseIdentifier:@"package"];
	cell.package = packages[indexPath.row];
	cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	[searchBar setShowsCancelButton:NO animated:YES];
	[self searchBar:searchBar textDidChange:(searchBar.text = @"")];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	[searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	packages = nil;
	[self.tableView reloadData];
	if (searchText.length) {
		__block NSString *prefix = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			self->packages = [Package latestSortedPackagesFromPackageArray:[Database.sharedInstance.sortedRemotePackages
				filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"package BEGINSWITH[cd] %@", prefix]
			]];
			prefix = nil;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.tableView reloadData];
			});
		});
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	PackageDetailsController *vc = [[PackageDetailsController alloc] initWithPackage:packages[indexPath.row]];
	if (vc) {
		[self.navigationController pushViewController:vc animated:YES];
	}
}

@end
