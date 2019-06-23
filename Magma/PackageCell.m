#import "PackageCell.h"
#import "Package.h"

@implementation PackageCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)setPackage:(Package *)package {
    self.textLabel.text = package.name ?: package.package;
    self.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", package.version, package.shortDescription];
}

@end