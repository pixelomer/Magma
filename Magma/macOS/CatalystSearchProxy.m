//
//  CatalystSearchProxy.m
//  Magma
//
//  Created by PixelOmer on 6.10.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#if TARGET_OS_MACCATALYST
#import "CatalystSearchProxy.h"
#import "CatalystSplitViewController.h"

@interface CatalystSplitViewController(Private)
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;
@end

@implementation CatalystSearchProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
	NSLog(@"%@", NSStringFromSelector(selector));
	return [_delegate methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	invocation.target = _delegate;
	[invocation invoke];
}

#define format @"<SearchProxy: %@>"

- (NSString *)description {
	return [NSString stringWithFormat:format, _delegate.description];
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:format, _delegate.debugDescription];
}

#undef format

- (BOOL)respondsToSelector:(SEL)selector {
    return [_delegate respondsToSelector:selector] || (selector == @selector(searchBar:textDidChange:));
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	[_splitViewController searchBar:searchBar textDidChange:searchText];
    if ([_delegate respondsToSelector:_cmd]) {
        [_delegate searchBar:searchBar textDidChange:searchText];
    }
}

@end

#endif
