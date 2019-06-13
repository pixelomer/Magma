#import "HomeViewController.h"

@implementation HomeViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Home";
}

- (void)didReceiveDatabaseNotification:(NSNotification *)notification {
	[super didReceiveDatabaseNotification:notification];
	if ([notification.name isEqualToString:DatabaseDidEncounterAnError]) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Database Error" message:notification.userInfo[@"error"] preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction
			actionWithTitle:@"Dismiss"
			style:UIAlertActionStyleCancel
			handler:nil
		]];
		[self.tabBarController presentViewController:alertController animated:YES completion:nil];
	}
}

@end