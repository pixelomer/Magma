#import "Database.h"

@implementation Database

static Database *sharedInstance;

+ (void)load {
	if ([self class] == [Database class]) {
		[self sharedInstance];
	}
}

+ (instancetype)alloc {
	return sharedInstance ? nil : [super alloc];
}

+ (instancetype)sharedInstance {
	if (!sharedInstance) {
		sharedInstance = [self new];
		[sharedInstance loadData];
	}
	return sharedInstance;
}

- (BOOL)isLoaded {
	return _isLoaded;
}

- (void)loadData {
	if (!_isLoaded) {
		// Load data from the filesystem
	}
}

@end