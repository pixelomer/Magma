#import "MGTableViewController.h"

@implementation MGTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
	if ((self = [super init])) {
		_delegate = self;
		_dataSource = self;
		self->style = style;
	}
	return self;
}

- (instancetype)init {
	return [self initWithStyle:UITableViewStylePlain];
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

- (UITableView *)setupTableView {
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:style];
	tableView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:tableView];
	[self.view addConstraints:@[
		[NSLayoutConstraint
			constraintWithItem:tableView
			attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeLeft
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:tableView
			attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeRight
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:tableView
			attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeTop
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:tableView
			attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeBottom
			multiplier:1.0
			constant:0.0
		]
	]];
	return tableView;
}

- (void)_setupTableView {
	_tableView = [self setupTableView];
	_tableView.dataSource = _dataSource ?: self;
	_tableView.delegate = _delegate ?: self;
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
