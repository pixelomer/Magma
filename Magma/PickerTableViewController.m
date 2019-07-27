//
//  PickerTableViewController.m
//  Magma
//
//  Created by PixelOmer on 27.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "PickerTableViewController.h"

@implementation PickerTableViewController

- (instancetype)init {
	return [self initWithStyle:UITableViewStyleGrouped];
}

- (void)setAllowsMultipleSelections:(BOOL)allowsMultipleSelections {
	[self throwIfLoaded];
	_allowsMultipleSelections = allowsMultipleSelections;
}

- (void)throwIfLoaded {
	if (self.isViewLoaded) {
		[NSException raise:NSInternalInconsistencyException format:@"You can't set this value while the view is loaded."];
	}
}

- (void)setOptions:(NSDictionary<NSString *, id> *)options {
	[self throwIfLoaded];
	_options = options;
}

- (void)setSelectedOptions:(NSArray<id> *)selectedOptions {
	[self throwIfLoaded];
	_selectedOptions = selectedOptions;
}

- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options allowsMultipleSelections:(BOOL)allowsMultipleSelections {
	if ((self = [self init])) {
		_options = options;
		_allowsMultipleSelections = allowsMultipleSelections;
	}
	return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _options.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	cell.accessoryType = [_selectedOptions containsObject:values[indexPath.row]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.textLabel.text = visibleOptions[indexPath.row];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (_allowsMultipleSelections) {
		
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _selectedOptions = _selectedOptions.copy;
    visibleOptions = [_options.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *mValues = [NSMutableArray copy];
    for (NSString *key in visibleOptions) {
    	[mValues addObject:_options[key]];
	}
	values = mValues.copy;
}

@end
