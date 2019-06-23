#import "SectionPackagesController.h"

@implementation SectionPackagesController

- (instancetype)initWithSection:(NSString *)section inSource:(Source *)source {
	return [self initWithFilters:@{
		@"source" : (id)source ?: NSNull.null,
		@"section" : section
	}];
}

@end