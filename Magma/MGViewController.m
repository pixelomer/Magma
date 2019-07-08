#import "MGViewController.h"

@class Source;

@implementation MGViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	self.view.backgroundColor = [UIColor whiteColor];
	[NSNotificationCenter.defaultCenter
		addObserver:self
		selector:@selector(_didReceiveDatabaseNotification:)
		name:nil
		object:Database.sharedInstance
	];
	if (_waitForDatabase.boolValue && !Database.sharedInstance.isLoaded) {
		containerView = [UIView new];
		containerView.translatesAutoresizingMaskIntoConstraints = NO;
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5);
		activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
		loadingLabel = [UILabel new];
		loadingLabel.font = [UIFont systemFontOfSize:18.0];
		loadingLabel.lineBreakMode = NSLineBreakByWordWrapping;
		loadingLabel.numberOfLines = 0;
		loadingLabel.textAlignment = NSTextAlignmentCenter;
		loadingLabel.text = @"Loading...";
		loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[containerView addSubview:loadingLabel];
		[containerView addSubview:activityIndicator];
		NSDictionary *views = @{ @"indicator" : activityIndicator, @"label" : loadingLabel };
		[containerView addConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"V:|[indicator(30)]-10-[label(>=0)]|"
			options:NSLayoutFormatAlignAllCenterX
			metrics:nil
			views:views
		]];
		[containerView addConstraints:@[
			[NSLayoutConstraint
				constraintWithItem:loadingLabel
				attribute:NSLayoutAttributeCenterX
				relatedBy:NSLayoutRelationEqual
				toItem:containerView
				attribute:NSLayoutAttributeCenterX
				multiplier:1.0
				constant:0.0
			],
			[NSLayoutConstraint
				constraintWithItem:loadingLabel
				attribute:NSLayoutAttributeWidth
				relatedBy:NSLayoutRelationLessThanOrEqual
				toItem:containerView
				attribute:NSLayoutAttributeWidth
				multiplier:1.0
				constant:-30.0
			],
			[NSLayoutConstraint
				constraintWithItem:activityIndicator
				attribute:NSLayoutAttributeWidth
				relatedBy:NSLayoutRelationEqual
				toItem:nil
				attribute:0
				multiplier:1.0
				constant:30.0
			],
			[NSLayoutConstraint
				constraintWithItem:loadingLabel
				attribute:NSLayoutAttributeWidth
				relatedBy:NSLayoutRelationGreaterThanOrEqual
				toItem:nil
				attribute:0
				multiplier:0.0
				constant:0.0
			]
		]];
		[self.view addSubview:containerView];
		views = @{ @"container" : containerView };
		[self.view addConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"H:|[container]|"
			options:0
			metrics:nil
			views:views
		]];
		[self.view addConstraint:[NSLayoutConstraint
			constraintWithItem:containerView
			attribute:NSLayoutAttributeCenterY
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeCenterY
			multiplier:1.0
			constant:0.0
		]];
		[activityIndicator startAnimating];
	}
	if (Database.sharedInstance.isLoaded) {
		[self databaseDidLoad:Database.sharedInstance];
	}
}

- (void)_didReceiveDatabaseNotification:(NSNotification *)_notification {
	__block NSNotification *notification = _notification;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self didReceiveDatabaseNotification:notification];
		notification = nil;
	});
}

- (void)didReceiveDatabaseNotification:(NSNotification *)notification {
	if ([notification.name isEqualToString:DatabaseDidLoad] && !_databaseDidLoad) {
		[self databaseDidLoad:notification.object];
	}
	else if ([notification.name isEqualToString:DatabaseDidAddSource]) {
		[self database:notification.object didAddSource:notification.userInfo[@"source"]];
	}
	else if ([notification.name isEqualToString:DatabaseDidRemoveSource]) {
		[self database:notification.object didRemoveSource:notification.userInfo[@"source"]];
	}
	else if ([notification.name isEqualToString:SourceDidStartRefreshing]) {
		[self sourceDidStartRefreshing:notification.userInfo[@"source"]];
	}
	else if ([notification.name isEqualToString:SourceDidStopRefreshing]) {
		[self sourceDidStopRefreshing:notification.userInfo[@"source"] reason:notification.userInfo[@"reason"]];
	}
	else if ([notification.name isEqualToString:DatabaseDidFinishRefreshingSources]) {
		[self databaseDidFinishRefreshingSources:notification.object];
	}
	else if ([notification.name isEqualToString:DatabaseDidStartRefreshingSources]) {
		[self databaseDidStartRefreshingSources:notification.object];
	}
}

- (void)databaseDidStartRefreshingSources:(Database *)database {}
- (void)databaseDidFinishRefreshingSources:(Database *)database {}
- (void)sourceDidStartRefreshing:(Source *)source {}
- (void)sourceDidStopRefreshing:(Source *)source reason:(NSString *)reason {}
- (void)database:(Database *)database didAddSource:(Source *)source {}
- (void)database:(Database *)database didRemoveSource:(Source *)source {}

- (void)databaseDidLoad:(Database *)database {
	if (!_databaseDidLoad) {
		_databaseDidLoad = YES;
		[activityIndicator stopAnimating];
		[activityIndicator removeFromSuperview];
		[loadingLabel removeFromSuperview];
		[containerView removeFromSuperview];
		activityIndicator = (id)(loadingLabel = (id)(containerView = nil));
	}
}

- (void)setWaitForDatabase:(NSNumber *)waitForDatabase {
	if (self.viewLoaded) {
		@throw [NSException
			exceptionWithName:NSInternalInconsistencyException
			reason:@"\"waitForDatabase\" property can only be set when the view isn't loaded."
			userInfo:nil
		];
	}
	else _waitForDatabase = waitForDatabase;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
