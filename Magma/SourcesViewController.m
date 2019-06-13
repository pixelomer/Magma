#import "SourcesViewController.h"
#import "SourceCell.h"
#import "Source.h"
#import <objc/runtime.h>

@implementation SourcesViewController

- (void)resetMainButtons {
	self.navigationItem.leftBarButtonItem.title = @"Refresh";
	self.navigationItem.rightBarButtonItem.title = @"Edit";
	self.navigationItem.leftBarButtonItem.style = self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
	self.navigationItem.rightBarButtonItem.tintColor = self.navigationItem.leftBarButtonItem.tintColor = (!Database.sharedInstance.isRefreshing ? self.view.tintColor : UIColor.grayColor);
}

- (void)switchEditMode {
	if (Database.sharedInstance.isRefreshing) return;
	[sourcesTableView setEditing:!sourcesTableView.isEditing animated:YES];
	if (!sourcesTableView.isEditing) {
		[self resetMainButtons];
	}
	else {
		self.navigationItem.leftBarButtonItem.title = @"Add";
		self.navigationItem.rightBarButtonItem.title = @"Done";
		self.navigationItem.rightBarButtonItem.style = (sourcesTableView.isEditing ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain);
	}
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

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Sources";
	self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)handleLeftBarButton {
	if (sourcesTableView.isEditing) [self showAddSourceAlert];
	else if (!Database.sharedInstance.isRefreshing)         [self startRefreshing];
}

- (void)showAddSourceAlert {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter Source Info" message:nil preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction
		actionWithTitle:@"Cancel"
		style:UIAlertActionStyleCancel
		handler:nil
	]];
	[alertController addAction:[UIAlertAction
		actionWithTitle:@"Add Source"
		style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *action){
			NSString *baseURL, *dist;
			NSString *components = dist = baseURL = nil;
			for (UITextField *textField in alertTextFields) {
				NSNumber *alertFieldIdentifier = objc_getAssociatedObject(textField, @selector(alertFieldIdentifier));
				NSString *value = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				switch (alertFieldIdentifier.shortValue) {
					case 0:    baseURL = value; break;
					case 1:       dist = value; break;
					case 2: components = value; break;
				}
			}
			if (components.length <= 0 || dist.length <= 0) {
				[Database.sharedInstance addSourceWithURL:baseURL];
			}
			else {
				[Database.sharedInstance addSourceWithBaseURL:baseURL distribution:dist components:components];
			}
			alertTextFields = nil;
		}
	]];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Base URL";
		textField.text = @"https://";
		objc_setAssociatedObject(textField, @selector(alertFieldIdentifier), @0, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Distribution (optional)";
		textField.text = @"./";
		objc_setAssociatedObject(textField, @selector(alertFieldIdentifier), @1, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Components (optional)";
		objc_setAssociatedObject(textField, @selector(alertFieldIdentifier), @2, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	// TODO: Another field for the architecture maybe?
	for (UITextField *textField in alertController.textFields) {
		textField.keyboardType = UIKeyboardTypeDefault;
	}
	alertTextFields = alertController.textFields.copy;
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)database:(Database *)database didAddSource:(Source *)source {
	[self reloadData];
}

- (void)database:(Database *)database didRemoveSource:(Source *)source {
	NSInteger index;
	if ((index = [sources indexOfObject:source]) != NSNotFound) {
		[sources removeObjectAtIndex:index];
		[sourcesTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)sourceDidStartRefreshing:(Source *)source {
	NSInteger index;
	if ((index = [sources indexOfObject:source]) != NSNotFound) {
		[sourcesTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)sourceDidStopRefreshing:(Source *)source reason:(NSString *)reason {
	NSInteger index;
	if ((index = [sources indexOfObject:source]) != NSNotFound) {
		[sourcesTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)databaseDidFinishRefreshingSources:(Database *)database {
	[self resetMainButtons];
}

- (void)startRefreshing {
	if (sourcesTableView.isEditing) [self switchEditMode];
	[Database.sharedInstance startRefreshingSources];
	[self resetMainButtons];
}

- (void)reloadData {
	sources = Database.sharedInstance.sources.mutableCopy;
	[sourcesTableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (section == 0) ? 1 : sources.count;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"all"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"all"];
		cell.textLabel.text = @"All packages";
		return cell;
	}
	else {
		SourceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"source"] ?: [[SourceCell alloc] initWithReuseIdentifier:@"source"];
		cell.source = sources[indexPath.row];
		cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ((indexPath.section == 1) && (editingStyle == UITableViewCellEditingStyleDelete)) {
		[Database.sharedInstance removeSource:sources[indexPath.row]];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!indexPath.section && !indexPath.row) {
		// Handle "All Packages"
	}
	else {
		// Handle individual source
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return tableView.isEditing && !Database.sharedInstance.isRefreshing && (indexPath.section == 1) && (sources[indexPath.row].databaseID >= 0);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return (section == 1) ? @"Invidiual Sources" : nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

@end