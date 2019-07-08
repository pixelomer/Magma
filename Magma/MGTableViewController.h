#import "MGViewController.h"

@interface MGTableViewController : MGViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly, strong) UITableView *tableView;
@property (nonatomic, weak) id<UITableViewDataSource> dataSource;
@property (nonatomic, weak) id<UITableViewDelegate> delegate;
- (void)pushViewController:(__kindof UIViewController *)vc animated:(BOOL)animated;
- (UITableView *)setupTableView; // Override this and return your own table view to modify the layout.
                                 // You must add the tableView as a subview yourself.
                                 // Do not modify the dataSource and delegate properties in the tableView directly.
@end
