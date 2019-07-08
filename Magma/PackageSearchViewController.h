#import "MGTableViewController.h"

@interface PackageSearchViewController : MGTableViewController<UISearchBarDelegate> {
	NSArray *packages;
}
@property (nonatomic, readonly, strong) UISearchBar *searchBar;
@end
