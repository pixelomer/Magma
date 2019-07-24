#import "HomeViewController.h"

@implementation HomeViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
	self.title = @"Featured";
}

- (void)showSettings {
	// Show settings
}

@end
