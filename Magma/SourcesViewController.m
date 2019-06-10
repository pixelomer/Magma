#import "SourcesViewController.h"
#import "SourceCell.h"

@implementation SourcesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Sources";
	self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)databaseDidLoad:(Database *)database {
	[super databaseDidLoad:database];
	sourcesTableView = [UITableView new];
	sourcesTableView.dataSource = self;
	sourcesTableView.delegate = self;
	sourcesTableView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:sourcesTableView];
	[self.view addConstraints:@[
		[NSLayoutConstraint
			constraintWithItem:sourcesTableView
			attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeLeft
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:sourcesTableView
			attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeRight
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:sourcesTableView
			attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeTop
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint
			constraintWithItem:sourcesTableView
			attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationEqual
			toItem:self.view
			attribute:NSLayoutAttributeBottom
			multiplier:1.0
			constant:0.0
		]
	]];
	[self reloadData];
}

- (void)reloadData {
	sources = Database.sharedInstance.sources;
	[sourcesTableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return sources.count;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	SourceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[SourceCell alloc] initWithReuseIdentifier:@"cell"];
	cell.source = sources[indexPath.row];
	return cell;
}

@end