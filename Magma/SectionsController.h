#import "MGTableViewController.h"

@interface SectionsController : MGTableViewController {
	NSDictionary<NSString *, NSNumber *> *sections;
	NSArray *sortedSections;
	NSNumber *totalPackageCount;
}
@property (nonatomic, readonly, weak) Source *source;
- (instancetype)initWithSource:(Source *)source;
@end
