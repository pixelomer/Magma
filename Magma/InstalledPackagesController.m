#import "InstalledPackagesController.h"

@implementation InstalledPackagesController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Installed";
}

- (instancetype)init {
    return [self initWithFilters:@{
        @"includeRemotePackages" : @NO,
		@"includeLocalPackages" : @YES,
    }];
}

@end