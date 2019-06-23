#import "MGTableViewController.h"

@interface PackagesController : MGTableViewController
@property (nonatomic, readonly, copy) NSString *section;
@property (nonatomic, readonly, copy) NSArray *packages;
@property (nonatomic, readonly, weak) Source *source;
- (instancetype)initWithFilters:(NSDictionary *)customFilters;
@end