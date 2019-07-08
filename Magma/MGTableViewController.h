#import "MGViewController.h"

@interface MGTableViewController : MGViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly, strong) UITableView *tableView;
@property (nonatomic, weak) id<UITableViewDataSource> dataSource;
@property (nonatomic, weak) id<UITableViewDelegate> delegate;
- (void)pushViewController:(__kindof UIViewController *)vc animated:(BOOL)animated;
@end
