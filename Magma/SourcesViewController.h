#import "MGTableViewController.h"

@class Source;

@interface SourcesViewController : MGTableViewController<UITextFieldDelegate> {
	NSMutableArray<Source *> *sources;
	BOOL isRefreshing;
}
@end
