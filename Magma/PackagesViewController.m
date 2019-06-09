#import "PackagesViewController.h"

@implementation PackagesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Installed Packages";
}

- (void)databaseDidLoad:(Database *)database {
	[super databaseDidLoad:database];
}

@end