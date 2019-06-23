#import "PackagesController.h"

@interface SectionPackagesController : PackagesController
- (instancetype)initWithSection:(NSString *)section inSource:(Source *)source;
@end