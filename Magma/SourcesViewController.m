#import "SourcesViewController.h"
#import "SourceCell.h"
#import "Source.h"
#import <objc/runtime.h>
#import "SectionsController.h"
#import "PackagesController.h"

@implementation SourcesViewController

- (void)resetMainButtons {
	self.navigationItem.leftBarButtonItem.title = @"Refresh";
	self.navigationItem.rightBarButtonItem.title = @"Edit";
	self.navigationItem.leftBarButtonItem.style = self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
	self.navigationItem.rightBarButtonItem.tintColor = self.navigationItem.leftBarButtonItem.tintColor = (!Database.sharedInstance.isRefreshing ? self.view.tintColor : UIColor.grayColor);
}

- (void)switchEditMode {
	if (Database.sharedInstance.isRefreshing) return;
	[self.tableView setEditing:!self.tableView.isEditing animated:YES];
	if (!self.tableView.isEditing) {
		[self resetMainButtons];
	}
	else {
		self.navigationItem.leftBarButtonItem.title = @"Add";
		self.navigationItem.rightBarButtonItem.title = @"Done";
		self.navigationItem.rightBarButtonItem.style = (self.tableView.isEditing ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain);
	}
}

- (void)databaseDidLoad:(Database *)database {
	[super databaseDidLoad:database];
	self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
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
	[self reloadData];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Sources";
	self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)handleLeftBarButton {
	if (self.tableView.isEditing) [self showAddSourceAlert];
	else if (!Database.sharedInstance.isRefreshing) [self startRefreshing];
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
			NSString *components, *baseURL, *dist = @"./", *architecture;
			for (UITextField *textField in self->alertTextFields) {
				NSNumber *alertFieldIdentifier = objc_getAssociatedObject(textField, _cmd);
				NSString *value = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				switch (alertFieldIdentifier.shortValue) {
					case 0:      baseURL = value; break;
					case 1:         dist = value; break;
					case 2:   components = value; break;
					case 3: architecture = value; break;
				}
			}
			if (!baseURL.length || !dist.length || !architecture.length);
			else if (components.length <= 0 || dist.length <= 0) {
				[Database.sharedInstance addSourceWithURL:baseURL architecture:architecture];
			}
			else {
				[Database.sharedInstance addSourceWithBaseURL:baseURL architecture:architecture distribution:dist components:components];
			}
			self->alertTextFields = nil;
		}
	]];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Base URL";
		objc_setAssociatedObject(textField, _cmd, @0, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Distribution (optional)";
		objc_setAssociatedObject(textField, _cmd, @1, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Components (optional)";
		objc_setAssociatedObject(textField, _cmd, @2, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Architecture";
		textField.text = @"amd64";
		objc_setAssociatedObject(textField, _cmd, @3, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
		[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)sourceDidStartRefreshing:(Source *)source {
	NSInteger index;
	if ((index = [sources indexOfObject:source]) != NSNotFound) {
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)sourceDidStopRefreshing:(Source *)source reason:(NSString *)reason {
	NSInteger index;
	if ((index = [sources indexOfObject:source]) != NSNotFound) {
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)databaseDidFinishRefreshingSources:(Database *)database {
	UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
	[self resetMainButtons];
}

- (void)startRefreshing {
	if (self.tableView.isEditing) [self switchEditMode];
	[Database.sharedInstance startRefreshingSources];
	[self resetMainButtons];
	UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
}

- (void)reloadData {
	sources = Database.sharedInstance.sources.mutableCopy;
	[self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (section == 0) ? 1 : sources.count;
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	__kindof UITableViewCell *cell;
	if (indexPath.section == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"all"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"all"];
		cell.textLabel.text = @"All Sources";
	}
	else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"source"] ?: [[SourceCell alloc] initWithReuseIdentifier:@"source"];
		[(SourceCell *)cell setSource:sources[indexPath.row]];
	}
	cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ((indexPath.section == 1) && (editingStyle == UITableViewCellEditingStyleDelete)) {
		[Database.sharedInstance removeSource:sources[indexPath.row]];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	__kindof UIViewController *vc;
	if (!indexPath.section && !indexPath.row) {
		vc = [[SectionsController alloc] initWithSource:nil];
	}
	else {
		Source *source = sources[indexPath.row];
		vc = [[SectionsController alloc] initWithSource:source];
	}
	if (vc) {
		[self.navigationController pushViewController:vc animated:YES];
	}
	else {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return tableView.isEditing && !Database.sharedInstance.isRefreshing && (indexPath.section == 1) && (sources[indexPath.row].databaseID >= 0);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return (section == 1) ? @"Individual Sources" : nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section ? 57.5 : 43.5;
}

@end
