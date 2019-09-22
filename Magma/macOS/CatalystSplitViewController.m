//
//  CatalystSplitViewController.m
//  Magma
//
//  Created by PixelOmer on 22.09.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST
#import "CatalystSplitViewController.h"
#import "UIImage+ResizeImage.h"

@implementation CatalystSplitViewControllerCell : UITableViewCell

- (void)layoutSubviews {
	[super layoutSubviews];
    self.imageView.bounds = CGRectMake(0, 0, 30, 48);
    self.textLabel.frame = CGRectMake(58, self.textLabel.frame.origin.y+1, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
}

@end

@implementation CatalystSplitViewController

- (instancetype)init {
	self = [super init];
	self.minimumPrimaryColumnWidth = self.maximumPrimaryColumnWidth = 300.0;
    _tableViewController = [UITableViewController new];
    _tableViewController.tableView.contentInset = UIEdgeInsetsMake(80, 0, 0, 0);
    _tableViewController.tableView.scrollEnabled = NO;
    _tableViewController.tableView.dataSource = self;
    _tableViewController.tableView.delegate = self;
    [super setViewControllers:@[_tableViewController]];
    self.primaryBackgroundStyle = UISplitViewControllerBackgroundStyleSidebar;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setViewControllers:(NSArray *)viewControllers {
	_viewControllers = viewControllers;
	if (_viewControllers.count) {
		super.viewControllers = @[_tableViewController, _viewControllers.firstObject];
	}
	else {
		super.viewControllers = @[_tableViewController];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _viewControllers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (!(cell = [_tableViewController.tableView dequeueReusableCellWithIdentifier:@"cell"])) {
		cell = [[CatalystSplitViewControllerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
		cell.textLabel.font = [UIFont systemFontOfSize:23.0];
		cell.textLabel.textColor = [UIColor colorNamed:@"TextColor"];
		cell.imageView.tintColor = [UIColor colorNamed:@"TextColor"];
		UIView *selectedBackground = [UIView new];
		selectedBackground.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.275];
		cell.selectedBackgroundView = selectedBackground;
	}
	UIViewController *vc = _viewControllers[indexPath.row];
	cell.textLabel.text = vc.tabBarItem.title;
	cell.imageView.image = [vc.tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	super.viewControllers = @[_tableViewController, _viewControllers[indexPath.row]];
}

@end

#endif
