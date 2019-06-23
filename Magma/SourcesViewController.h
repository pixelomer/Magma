#import "MGTableViewController.h"

@class Source;

@interface SourcesViewController : MGTableViewController {
	NSMutableArray<Source *> *sources;
	NSArray<UITextField *> *alertTextFields;
	BOOL isRefreshing;
}
@end