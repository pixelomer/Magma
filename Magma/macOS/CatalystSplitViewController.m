//
//  CatalystSplitViewController.m
//  Magma
//
//  Created by PixelOmer on 22.09.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#if TARGET_OS_MACCATALYST
#import "CatalystSplitViewController.h"
#import "UIImage+ResizeImage.h"
#import <objc/runtime.h>
#import "CatalystSplitViewControllerCell.h"
#import "CatalystSearchProxy.h"

#define DEFAULT_INSET 50
#define SEARCH_BAR_INSET 100

static id (*MagmaCatalystTabBarControllerOrig)(UIViewController *self, SEL _cmd);
static id MagmaCatalystTabBarControllerHook(UIViewController *self, SEL _cmd) {
    UIViewController *vc = MagmaCatalystTabBarControllerOrig(self, _cmd);
    if (vc) return vc;
    vc = self;
    while ((vc = vc.parentViewController)) {
        if ([vc isKindOfClass:[CatalystSplitViewController class]]) {
            return vc;
        }
    }
    return nil;
}

@implementation CatalystSplitViewController

+ (void)initialize {
    if (self == [CatalystSplitViewController class]) {
        Method m = class_getInstanceMethod([UIViewController class], @selector(tabBarController));
        MagmaCatalystTabBarControllerOrig = (id(*)(id,SEL))method_getImplementation(m);
        method_setImplementation(m, (IMP)MagmaCatalystTabBarControllerHook);
    }
}

- (instancetype)init {
	self = [super init];
	self.minimumPrimaryColumnWidth = self.maximumPrimaryColumnWidth = 250.0;
    _tableViewController = [UITableViewController new];
    _tableViewController.tableView.contentInset = UIEdgeInsetsMake(DEFAULT_INSET, 0, 0, 0);
    _tableViewController.tableView.scrollEnabled = NO;
    _tableViewController.tableView.dataSource = self;
    _tableViewController.tableView.delegate = self;
    _tableViewController.clearsSelectionOnViewWillAppear = NO;
    _emptyVC = [UIViewController new];
    self.viewControllers = _viewControllers;
    self.primaryBackgroundStyle = UISplitViewControllerBackgroundStyleSidebar;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *container = [UIView new];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [_tableViewController.view addSubview:container];
    [container.topAnchor constraintEqualToAnchor:_tableViewController.view.safeAreaLayoutGuide.topAnchor].active = YES;
    [container.leftAnchor constraintEqualToAnchor:_tableViewController.view.safeAreaLayoutGuide.leftAnchor].active = YES;
    [container.rightAnchor constraintEqualToAnchor:_tableViewController.view.safeAreaLayoutGuide.rightAnchor].active = YES;
    [container.heightAnchor constraintEqualToConstant:80].active = YES;
    _searchBar = [UISearchBar new];
    _searchBar.searchBarStyle = UISearchBarStyleMinimal;
	_searchBar.backgroundColor = [UIColor colorNamed:@"SearchBarColor"];
	_searchBar.layer.masksToBounds = YES;
	_searchBar.layer.cornerRadius = 6.0;
    _searchBar.placeholder = @"Search";
    _searchBar.hidden = YES;
    _searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:_searchBar];
    [_searchBar.centerXAnchor constraintEqualToAnchor:container.centerXAnchor].active = YES;
    [_searchBar.centerYAnchor constraintEqualToAnchor:container.centerYAnchor].active = YES;
    [_searchBar.widthAnchor constraintEqualToAnchor:container.widthAnchor constant:-40].active = YES;
    [_searchBar.heightAnchor constraintEqualToConstant:35].active = YES;
    _searchProxy = [CatalystSearchProxy alloc];
    _searchProxy.splitViewController = self;
    _searchBar.delegate = _searchProxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)cmd {
    return [super methodSignatureForSelector:cmd] ?: [UITabBarController instanceMethodSignatureForSelector:cmd];
}

- (void)forwardInvocation:(NSInvocation *)inv {
    if ([UITabBarController instancesRespondToSelector:inv.selector]) {
        inv.target = nil;
        [inv invoke];
    }
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	static BOOL didAppearBefore = NO;
	if (!didAppearBefore) {
		didAppearBefore = YES;
		self.viewControllers = _viewControllers;
	}
}

- (void)resetSearchBarDelegate {
    if (!_searchTabIndex) {
        _searchProxy.delegate = nil;
        _realSearchTabIndex = 0;
        return;
    }
    if (!_viewControllers.count) {
        [NSException raise:NSInvalidArgumentException format:@"viewControllers cannot be empty while search tab is enabled"];
    }
    NSInteger intValue = [_searchTabIndex integerValue];
    if (intValue < 0) intValue = _viewControllers.count + intValue;
    if ((intValue < 0) || (intValue >= _viewControllers.count)) {
        [NSException raise:NSInvalidArgumentException format:@"Search tab index (%li) is out of range: {0 ... %lu}", (long)_realSearchTabIndex, _viewControllers.count - 1];
    }
    __kindof UIViewController *vc = _viewControllers[(_realSearchTabIndex = intValue)];
    vc = [vc isKindOfClass:[UINavigationController class]] ? [(UINavigationController *)vc viewControllers].firstObject : vc;
    _searchProxy.delegate = (NSObject<UISearchBarDelegate> *)vc;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
	// WARNING: No error handling
	[_tableViewController.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [super setViewControllers:@[_tableViewController, _viewControllers[selectedIndex]]];
}

- (NSUInteger)selectedIndex {
	return _tableViewController.tableView.indexPathForSelectedRow.row;
}

- (void)setViewControllers:(NSArray *)viewControllers {
	_viewControllers = viewControllers;
	if (_viewControllers.count) {
		super.viewControllers = @[_tableViewController, _viewControllers.firstObject];
		[_tableViewController.tableView reloadData];
		[_tableViewController.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	else {
		super.viewControllers = @[_tableViewController, _emptyVC];
	}
    [self resetSearchBarDelegate];
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
		selectedBackground.backgroundColor = [UIColor colorNamed:@"SelectedTabColor"];
		cell.selectedBackgroundView = selectedBackground;
	}
	UIViewController *vc = _viewControllers[indexPath.row];
	cell.textLabel.text = vc.tabBarItem.title;
	cell.imageView.image = [vc.tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray<__kindof NSObject *> *newArray = @[_tableViewController, _viewControllers[indexPath.row]];
	if ([newArray isEqual:super.viewControllers]) {
		if ([newArray[1] isKindOfClass:[UINavigationController class]]) {
			[(UINavigationController *)newArray[1] popToRootViewControllerAnimated:YES];
		}
	}
	else super.viewControllers = newArray;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!_searchTabIndex) return;
	self.selectedIndex = _realSearchTabIndex;
}

- (void)setSearchTabIndex:(NSNumber *)searchTabIndex {
    if (searchTabIndex) {
        _tableViewController.tableView.contentInset = UIEdgeInsetsMake(SEARCH_BAR_INSET, 0, 0, 0);
        _searchBar.hidden = NO;
    }
    else {
        _tableViewController.tableView.contentInset = UIEdgeInsetsMake(DEFAULT_INSET, 0, 0, 0);
        _searchBar.hidden = YES;
    }
    _searchTabIndex = searchTabIndex;
    [self resetSearchBarDelegate];
}

@end

#endif
