#import "MGTableViewController.h"

@implementation MGTableViewController

- (instancetype)init {
	return [super init];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	NSIndexPath *selection = [self.tableView indexPathForSelectedRow];
	if (selection) {
		[_tableView deselectRowAtIndexPath:selection animated:YES];
	}
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
	_tableView.delegate = _delegate = delegate;
}

- (void)setDataSource:(id<UITableViewDataSource>)dataSource {
	_tableView.dataSource = _dataSource = dataSource;
}

- (void)_setupTableView {
	_tableView = [UITableView new];
	_tableView.dataSource = _dataSource ?: self;
	_tableView.delegate = _delegate ?: self;
	_tableView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:_tableView];
	[self.view addConstraints:@[
		[NSLayoutConstraint
			constraintWithItem:_tableView
			attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeLeft
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:_tableView
			attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeRight
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:_tableView
			attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeTop
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:_tableView
			attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeBottom
			multiplier:1.0
			constant:0.0
		]
	]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (!self.waitForDatabase.boolValue) {
    	[self _setupTableView];
	}
}

- (void)databaseDidLoad:(Database *)database {
    [super databaseDidLoad:database];
    if (self.waitForDatabase.boolValue) {
    	[self _setupTableView];
	}
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 0;
}

- (void)pushViewController:(__kindof UIViewController *)vc animated:(BOOL)animated {
	if (vc) {
		[self.navigationController pushViewController:vc animated:animated];
	}
	else if (_tableView.indexPathForSelectedRow) {
		[_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
	}
}

@end
