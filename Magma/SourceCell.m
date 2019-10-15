#import "SourceCell.h"
#import "Source.h"
#import "Database.h"
#import "UIImage+ResizeImage.h"

#define FractionKeyPath @"fractionCompleted"
#define ProgressKeyPath @"refreshProgress"

@implementation SourceCell

StaticKey(ProgressChange);
StaticKey(FractionChange);

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	self.separatorInset = UIEdgeInsetsZero;
	self.detailTextLabel.numberOfLines = self.textLabel.numberOfLines = 1;
	self.detailTextLabel.textColor = [UIColor colorWithRed:0.569 green:0.608 blue:0.635 alpha:1.0];
	self.textLabel.text = self.detailTextLabel.text = @"(Unknown)";
	_progressView = [UIProgressView new];
	_progressView.translatesAutoresizingMaskIntoConstraints = NO;
	_progressView.progressViewStyle = UIProgressViewStyleBar;
	[self addSubview:_progressView];
	[_progressView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active =
	[_progressView.leftAnchor constraintEqualToAnchor:self.leftAnchor].active =
	[_progressView.rightAnchor constraintEqualToAnchor:self.rightAnchor].active =
	[_progressView.heightAnchor constraintEqualToConstant:5.0].active = YES;
	[NSNotificationCenter.defaultCenter
		addObserver:self
		selector:@selector(sourceDidStartRefreshing:)
		name:SourceDidStartRefreshing
		object:nil
	];
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if (context == ProgressChange) {
		[_source.refreshProgress addObserver:self forKeyPath:FractionKeyPath options:0 context:FractionChange];
	}
	else if (context == FractionChange) {
		dispatch_async(dispatch_get_main_queue(), ^{
			_progressView.progress = _source.refreshProgress.fractionCompleted;
		});
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)removeConnections {
	[_source removeObserver:self forKeyPath:ProgressKeyPath];
	[_source.refreshProgress removeObserver:self forKeyPath:FractionKeyPath];
}

- (void)dealloc {
	[self removeConnections];
}

- (void)sourceDidStartRefreshing:(NSNotification *)notif {
	if (notif.userInfo[@"source"] == _source) {
		[_source.refreshProgress removeObserver:self forKeyPath:FractionKeyPath];
	}
}

- (void)setSource:(Source *)source {
	[self removeConnections];
	_source = source;
	[source addObserver:self forKeyPath:ProgressKeyPath options:0 context:ProgressChange];
	[source.refreshProgress addObserver:self forKeyPath:FractionKeyPath options:0 context:FractionChange];
	self.textLabel.text = source.origin ?: source.baseURL.host;
	self.detailTextLabel.text = source.baseURL.absoluteString;
}

@end
