#import "MGTableViewController.h"

@interface SectionsController : MGTableViewController {
	NSArray<NSString *> *sections;
}
@property (nonatomic, readonly, weak) Source *source;
- (instancetype)initWithSource:(Source *)source;
@end