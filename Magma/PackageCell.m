#import "PackageCell.h"
#import "Package.h"

@implementation PackageCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)setPackage:(Package *)package {
    self.textLabel.text = [NSString stringWithFormat:@"%@", package.package];
    self.detailTextLabel.text = package.shortDescription;
}

@end
