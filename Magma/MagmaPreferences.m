//
//  MagmaPreferences.m
//  Magma
//
//  Created by PixelOmer on 6.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "MagmaPreferences.h"
#import <objc/runtime.h>

@implementation MagmaPreferences

static NSUserDefaults *defaults;
static NSArray *list;

+ (NSArray<NSString *> *)list {
	return list;
}

+ (void)load {
	if (self == [MagmaPreferences class]) {
		defaults = [NSUserDefaults standardUserDefaults];
		list = @[
			@"Assume UTF-8",
			@"Default Architecture"
		];
		NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjects:@[
			@YES,
			@"amd64"
		] forKeys:list];
		[defaults registerDefaults:defaultsDict];
	}
}

+ (id)valueForKey:(NSString *)key {
	return [defaults valueForKey:key];
}

+ (void)setValue:(id)value forKey:(NSString *)key {
	[defaults setValue:value forKey:key];
}

+ (BOOL)assumesUTF8 {
	return [[self valueForKey:@"Assume UTF-8"] boolValue];
}

+ (NSString *)defaultArchitecture {
	return [self valueForKey:@"Default Architecture"];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
	return nil;
}

+ (instancetype)alloc {
	return nil;
}

- (instancetype)init {
	return nil;
}

@end
