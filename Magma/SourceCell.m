#import "SourceCell.h"
#import "Source.h"
#import "UIImage+ResizeImage.h"

@implementation SourceCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	self.imageView.image = [[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Applications/Cydia.app/Icon-60.png"]]] resizedImageOfSize:CGSizeMake(40, 40)];
	self.separatorInset = UIEdgeInsetsZero;
	self.imageView.layer.masksToBounds = YES;
	self.imageView.layer.cornerRadius = 10.0;
	self.textLabel.text = @"(Unknown)";
	self.detailTextLabel.textColor = [UIColor colorWithRed:0.569 green:0.608 blue:0.635 alpha:1.0];
	return self;
}

- (void)setSource:(Source *)source {
	_source = source;
	self.textLabel.text = source.parsedReleaseFile[@"origin"] ?: source.baseURL.host;
	self.detailTextLabel.text = source.baseURL.absoluteString;
}

@end