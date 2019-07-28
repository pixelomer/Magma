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
	NSString *className = NSStringFromClass(self.class);
	[NSException raise:NSInvalidArgumentException format:@"-[%@ init] is deprecated, use -[%@ initWithOptions:allowsMultipleSelections:] instead.", className, className];
	return nil;
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
	if (!options.count) [NSException raise:NSInvalidArgumentException format:@"Options dictionary must contain at least one value."];
	NSArray *allValues = options.allValues;
	for (NSInteger i = 0; i < allValues.count; i++) {
		@autoreleasepool {
			NSMutableArray *array = [allValues mutableCopy];
			[array removeObjectAtIndex:i];
			id object = allValues[i];
			if ([array indexOfObjectIdenticalTo:object] != NSNotFound) {
				[NSException raise:NSInvalidArgumentException format:@"Options dictionary cannot contain identical objects."];
			}
		}
	}
	_options = options;
}

- (NSArray<id> *)selectedOptions {
	return _selectedOptions.copy;
}

- (void)setSelectedOptions:(NSArray<id> *)selectedOptions {
	[self throwIfLoaded];
	_selectedOptions = selectedOptions.mutableCopy;
}

- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options allowsMultipleSelections:(BOOL)allowsMultipleSelections {
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.options = options;
		self.allowsMultipleSelections = allowsMultipleSelections;
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
	cell.accessoryType = ([_selectedOptions indexOfObjectIdenticalTo:values[indexPath.row]] != NSNotFound) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	if (_showsInternalValues) {
		@autoreleasepool {
			NSString *visibleValue = visibleOptions[indexPath.row];
			NSString *internalValue = values[indexPath.row];
			NSString *combinedValue = [NSString stringWithFormat:@"%@ [%@]", visibleValue, internalValue];
			NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:combinedValue];
			[string addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(visibleValue.length+1, internalValue.length+2)];
			cell.textLabel.attributedText = string.copy;
		}
	}
	else cell.textLabel.text = visibleOptions[indexPath.row];
	return cell;
}

- (void)setShowsInternalValues:(BOOL)showsInternalValues {
	_showsInternalValues = showsInternalValues;
	if (self.isViewLoaded) {
		[self.tableView reloadData];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL selectedItemsDidChange = YES;
	id object = values[indexPath.row];
	if (_allowsMultipleSelections) {
		if ([_selectedOptions indexOfObjectIdenticalTo:object] != NSNotFound) {
			[_selectedOptions removeObjectIdenticalTo:object];
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
		}
		else {
			[_selectedOptions addObject:object];
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	else {
		NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:[values indexOfObjectIdenticalTo:_selectedOptions[0]] inSection:0];
		if ((selectedItemsDidChange = (oldIndexPath.row != indexPath.row))) {
			_selectedOptions[0] = values[indexPath.row];
			[tableView cellForRowAtIndexPath:oldIndexPath].accessoryType = UITableViewCellAccessoryNone;
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (selectedItemsDidChange) {
		[_delegate pickerTableViewController:self selectedItemsDidChange:self.selectedOptions];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    visibleOptions = [_options.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *mValues = [NSMutableArray new];
    for (NSString *key in visibleOptions) {
    	[mValues addObject:_options[key]];
	}
	values = mValues.copy;
	if (!_selectedOptions) {
		_selectedOptions = [NSMutableArray new];
	}
	if (!_allowsMultipleSelections && (_selectedOptions.count != 1)) {
		_selectedOptions = @[values[0]].mutableCopy;
		[_delegate pickerTableViewController:self selectedItemsDidChange:self.selectedOptions];
	}
}

@end
