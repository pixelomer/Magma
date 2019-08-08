#import "SourcesViewController.h"
#import "SourceCell.h"
#import "Source.h"
#import <objc/runtime.h>
#import "MagmaPreferences.h"
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
		action:@selector(handleLeftBarButton:)
	];
	[self reloadData];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Sources";
}

- (void)handleLeftBarButton:(UIBarButtonItem *)button {
	if (self.tableView.isEditing) [self showAddSourceAlert:button];
	else if (!Database.sharedInstance.isRefreshing) [self startRefreshing];
}

- (void)showErrorMessage:(NSString *)message {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction
		actionWithTitle:@"OK"
		style:UIAlertActionStyleCancel
		handler:nil
	]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)showPPAAlert {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter PPA Details" message:nil preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction
		actionWithTitle:@"Cancel"
		style:UIAlertActionStyleCancel
		handler:nil
	]];
	UIAlertAction *addSourceAction = [UIAlertAction
		actionWithTitle:@"Add Source"
		style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *action){
			NSString *ppa, *dist, *arch;
			for (UITextField *textField in alertController.textFields) {
				NSNumber *alertFieldIdentifier = objc_getAssociatedObject(textField, _cmd);
				NSString *value = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				if (value.length) {
					switch (alertFieldIdentifier.shortValue) {
						case 0:  ppa = value; break;
						case 1: dist = value; break;
						case 2: arch = value; break;
					}
				}
			}
			if ([[Database.sharedInstance addPPA:ppa distribution:dist architecture:arch] isKindOfClass:NSNull.class]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self showErrorMessage:@"This source is already in your sources."];
				});
			}
		}
	];
	addSourceAction.enabled = NO;
	[alertController addAction:addSourceAction];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"PPA";
		textField.text = @"ppa:";
		objc_setAssociatedObject(textField, _cmd, @0, OBJC_ASSOCIATION_COPY_NONATOMIC);
		objc_setAssociatedObject(textField, @selector(textDidChange:), addSourceAction, OBJC_ASSOCIATION_ASSIGN);
		[textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
	}];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Distribution";
		textField.text = @"bionic";
		objc_setAssociatedObject(textField, _cmd, @1, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
		textField.placeholder = @"Architecture";
		textField.text = MagmaPreferences.defaultArchitecture;
		objc_setAssociatedObject(textField, _cmd, @2, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)textDidChange:(UITextField *)textField {
	[(UIAlertAction *)objc_getAssociatedObject(textField, _cmd) setEnabled:[textField.text containsString:@"/"]];
}

- (void)showAdvancedSourceAlert {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter Source Details" message:nil preferredStyle:UIAlertControllerStyleAlert];
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
			for (UITextField *textField in alertController.textFields) {
				NSNumber *alertFieldIdentifier = objc_getAssociatedObject(textField, _cmd);
				NSString *value = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				if (value.length) {
					switch (alertFieldIdentifier.shortValue) {
						case 0:      baseURL = value; break;
						case 1:         dist = value; break;
						case 2:   components = value; break;
						case 3: architecture = value; break;
					}
				}
			}
			short errorType = 0;
			if (!baseURL.length || !dist.length || !architecture.length) errorType = 2;
		#ifndef ALLOW_IOS_REPOSITORIES
			else if ([architecture isEqualToString:@"iphoneos-arm"]) errorType = 3;
		#endif
			else if (![baseURL isEqualToString:@"http://"] && ![baseURL isEqualToString:@"https://"]) errorType = 4;
			else if (components.length <= 0 || dist.length <= 0) {
				errorType = !![[Database.sharedInstance addSourceWithURL:baseURL architecture:architecture] isKindOfClass:NSNull.class];
			}
			else {
				errorType = !![[Database.sharedInstance addSourceWithBaseURL:baseURL architecture:architecture distribution:dist components:components] isKindOfClass:NSNull.class];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				switch (errorType) {
					case 1:
						[self showErrorMessage:@"This source is already in your sources."];
						break;
					case 2:
						[self showErrorMessage:@"You didn't specify the required parameters."];
						break;
		#ifndef ALLOW_IOS_REPOSITORIES
					case 3:
						[self showErrorMessage:@"This architecture is not supported."];
						break;
		#endif
					case 4:
						[self showErrorMessage:@"The URL must be an HTTP(S) URL."];
						break;
				}
			});
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
		textField.text = MagmaPreferences.defaultArchitecture;
		objc_setAssociatedObject(textField, _cmd, @3, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}];
	for (UITextField *textField in alertController.textFields) {
		textField.keyboardType = UIKeyboardTypeDefault;
	}
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)showAddSourceAlert:(UIBarButtonItem *)button {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add source..." message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	alertController.modalPresentationStyle = UIModalPresentationPopover;
	alertController.popoverPresentationController.barButtonItem = button;
	[alertController addAction:[UIAlertAction
		actionWithTitle:@"Custom Source"
		style:UIAlertActionStyleDefault
		handler:^(id action){
			[self showAdvancedSourceAlert];
		}
	]];
	[alertController addAction:[UIAlertAction
		actionWithTitle:@"PPA"
		style:UIAlertActionStyleDefault
		handler:^(id action){
			[self showPPAAlert];
		}
	]];
	[alertController addAction:[UIAlertAction
		actionWithTitle:@"Cancel"
		style:UIAlertActionStyleCancel
		handler:nil
	]];
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
	[self pushViewController:vc animated:YES];
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
