#import "MGViewController.h"

@class Source;

@interface SourcesViewController : MGViewController<UITableViewDataSource, UITableViewDelegate> {
	UITableView *sourcesTableView;
	NSArray<Source *> *sources;
}
@end