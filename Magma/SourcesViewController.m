#import "SourcesViewController.h"
#import "SourceCell.h"
#import "Source.h"

@implementation SourcesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Sources";
	self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)handleLeftBarButton {
	if (sourcesTableView.isEditing) [self showAddSourceAlert];
	else [self startRefreshing];
}

- (void)showAddSourceAlert {
	//UIAlertController *alertController = [[UIAlertController alloc] init];
	//[alertController addTextFieldWithConfigurationHandler:]
}

- (void)startRefreshing {

}

- (void)switchEditMode {
	[sourcesTableView setEditing:!sourcesTableView.isEditing animated:YES];
	[self.navigationItem.leftBarButtonItem setTitle:(sourcesTableView.isEditing ? @"Add" : @"Refresh")];
	[self.navigationItem.rightBarButtonItem setTitle:(sourcesTableView.isEditing ? @"Done" : @"Edit")];
	[self.navigationItem.rightBarButtonItem setStyle:(sourcesTableView.isEditing ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain)];
}

- (void)databaseDidLoad:(Database *)database {
	[super databaseDidLoad:database];
	sourcesTableView = [UITableView new];
	sourcesTableView.dataSource = self;
	sourcesTableView.delegate = self;
	sourcesTableView.translatesAutoresizingMaskIntoConstraints = NO;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:@"Edit"
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(switchEditMode)
	];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:@"Refresh"
		style:UIBarButtonItemStylePlain
		target:self
		action:@selector(handleLeftBarButton)
	];
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
	sources = Database.sharedInstance.sources.mutableCopy;
	[sourcesTableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return sources.count * !section;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	SourceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[SourceCell alloc] initWithReuseIdentifier:@"cell"];
	cell.source = sources[indexPath.row];
	cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[Database.sharedInstance removeSource:sources[indexPath.row]];
		[sources removeObjectAtIndex:indexPath.row];
		[sourcesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return sources[indexPath.row].databaseID >= 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

@end