#import "SourceCell.h"
#import "Source.h"
#import "UIImage+ResizeImage.h"

@implementation SourceCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	self.separatorInset = UIEdgeInsetsZero;
	self.detailTextLabel.numberOfLines = self.textLabel.numberOfLines = 1;
	self.detailTextLabel.textColor = [UIColor colorWithRed:0.569 green:0.608 blue:0.635 alpha:1.0];
	self.textLabel.text = self.detailTextLabel.text = @"(Unknown)";
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
	[self.textLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
	[self.detailTextLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
	[activityIndicator setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
	[self.contentView addSubview:activityIndicator];
	[self.contentView addConstraints:@[
		[NSLayoutConstraint
			constraintWithItem:activityIndicator
			attribute:NSLayoutAttributeTrailing
			relatedBy:NSLayoutRelationEqual
			toItem:self.contentView
			attribute:NSLayoutAttributeTrailing
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:activityIndicator
			attribute:NSLayoutAttributeCenterY
			relatedBy:NSLayoutRelationEqual
			toItem:self.contentView
			attribute:NSLayoutAttributeCenterY
			multiplier:1.0
			constant:0.0
		]
	]];
	[(UIImageView *)[activityIndicator valueForKey:@"_internalView"] setTransform:CGAffineTransformMakeScale(0.8, 0.8)];
	return self;
}

- (void)setSource:(Source *)source {
	_source = source;
	self.textLabel.text = source.parsedReleaseFile[@"origin"] ?: source.baseURL.host;
	self.detailTextLabel.text = source.baseURL.absoluteString;
	if (source.isRefreshing) {
		[activityIndicator startAnimating];
	}
	else {
		[activityIndicator stopAnimating];
	}
}

@end