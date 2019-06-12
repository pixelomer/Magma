#import "SourcesViewController.h"
#import "SourceCell.h"
#import "Source.h"
#import <objc/runtime.h>

@implementation SourcesViewController

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
#define trim(string) [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
				if ([alertFieldIdentifier isEqual:@0]) baseURL = trim(textField.text);
				if ([alertFieldIdentifier isEqual:@1]) dist = trim(textField.text);
				if ([alertFieldIdentifier isEqual:@2]) components = trim(textField.text);
#undef trim
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
		[sourcesTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)startRefreshing {

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
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return sources[indexPath.row].databaseID >= 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

@end