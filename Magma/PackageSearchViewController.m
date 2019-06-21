#import "PackageSearchViewController.h"

@implementation PackageSearchViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Search";
}

- (void)databaseDidLoad:(Database *)database {
    searchBar = [UISearchBar new];
}

@end