#import "MGViewController.h"

@class Source;

@interface SourcesViewController : MGViewController<UITableViewDataSource, UITableViewDelegate> {
	UITableView *sourcesTableView;
	NSMutableArray<Source *> *sources;
	BOOL isEditing;
}
@end