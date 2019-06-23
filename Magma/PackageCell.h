#import <UIKit/UIKit.h>

@class Package;

@interface PackageCell : UITableViewCell
- (void)setPackage:(Package *)package;
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
@end