//
//  PreferencesViewController.m
//  Magma
//
//  Created by PixelOmer on 6.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "PreferencesViewController.h"
#import "MagmaPreferences.h"

@implementation PreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (instancetype)init {
	tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	if (tableViewController && (self = [super initWithRootViewController:tableViewController])) {
		tableViewController.title = @"Preferences";
		tableViewController.tableView.dataSource = self;
		tableViewController.tableView.delegate = self;
		tableViewController.tableView.cellLayoutMarginsFollowReadableWidth = YES;
		tableViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didPressDoneButton)];
		return self;
	}
	return nil;
}

- (void)didPressDoneButton {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)textDidChange:(UITextField *)textField {
	[MagmaPreferences setValue:textField.text forKey:MagmaPreferences.list[textField.tag]];
}

- (void)switchDidChange:(UISwitch *)switchView {
	[MagmaPreferences setValue:@(switchView.on) forKey:MagmaPreferences.list[switchView.tag]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return MagmaPreferences.list.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 43.5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *itemName = MagmaPreferences.list[indexPath.row];
	__kindof NSObject *currentItem = [MagmaPreferences valueForKey:itemName];
	UITableViewCell *cell = nil;
	if ([currentItem isKindOfClass:[NSString class]]) {
		if (!(cell = [tableView dequeueReusableCellWithIdentifier:@"textFieldCell"])) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"textFieldCell"];
			UITextField *textField = [UITextField new];
			textField.translatesAutoresizingMaskIntoConstraints = NO;
			textField.textAlignment = NSTextAlignmentRight;
			textField.textColor = [UIColor grayColor];
			[textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
			[cell.contentView addSubview:textField];
			[textField.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor].active = YES;
			[textField.rightAnchor constraintEqualToAnchor:cell.contentView.readableContentGuide.rightAnchor].active = YES;
			[textField.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor].active = YES;
			[textField.widthAnchor constraintEqualToAnchor:cell.contentView.widthAnchor multiplier:0.35].active = YES;
		}
		UITextField *textField = (id)cell.contentView.subviews.lastObject;
		textField.tag = indexPath.row;
		textField.text = currentItem;
	}
	else if ([currentItem isKindOfClass:[NSNumber class]]) {
		if (!(cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"])) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"switchCell"];
			UISwitch *switchView = [UISwitch new];
			[switchView addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
			cell.accessoryView = switchView;
		}
		UISwitch *switchView = (id)cell.accessoryView;
		switchView.tag = indexPath.row;
		switchView.on = [(NSNumber *)currentItem boolValue];
	}
	cell.textLabel.text = itemName;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

@end
