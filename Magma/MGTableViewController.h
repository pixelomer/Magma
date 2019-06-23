#import "MGViewController.h"

@interface MGTableViewController : MGViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly, strong) UITableView *tableView;
@end