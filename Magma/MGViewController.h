#import <UIKit/UIKit.h>
#import "Database.h"

@interface MGViewController : UIViewController {
	@private
	BOOL _databaseDidLoad;
	UIActivityIndicatorView *activityIndicator;
	UILabel *loadingLabel;
	UIView *containerView;
}
@property (nonatomic, strong, setter=setWaitForDatabase:) NSNumber *waitForDatabase;

// This method will be called once the view loads.
- (void)viewDidLoad;

// This method will be called once the database is loaded if waitForDatabase is @YES. 
- (void)databaseDidLoad:(Database *)database;

// Override this method to receive other notifications from the database. You must call the super method if you want to keep the existing methods functional.
- (void)didReceiveDatabaseNotification:(NSNotification *)notification;

// Override these methods to receive notifications from the database.
- (void)sourceDidStartRefreshing:(Source *)source;
- (void)sourceDidStopRefreshing:(Source *)source reason:(NSString *)reason;
- (void)database:(Database *)database didAddSource:(Source *)source;
- (void)database:(Database *)database didRemoveSource:(Source *)source;
- (void)databaseDidFinishRefreshingSources:(Database *)database;
- (void)databaseDidStartRefreshingSources:(Database *)database;

@end
