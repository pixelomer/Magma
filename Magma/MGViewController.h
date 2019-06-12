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
- (void)viewDidLoad;
- (void)databaseDidLoad:(Database *)database;
- (void)setWaitForDatabase:(NSNumber *)waitForDatabase;
- (void)didReceiveDatabaseNotification:(NSNotification *)notification;
@end