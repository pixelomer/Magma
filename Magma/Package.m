#import "Package.h"
#import "Database.h"
#import <objc/runtime.h>

@implementation Package

+ (void)load {
	if ([self class] == [Package class]) {
		NSArray *selectors = @[
			@"author",
			@"maintainer",
			@"description",
			@"md5sum",
			@"sha1",
			@"sha256",
			@"version",
			@"filename",
			@"architecture",
			@"section",
			@"sha512"
		];
		for (NSString *selectorString in selectors) {
			SEL selector = NSSelectorFromString(selectorString);
			class_addMethod(self, selector, class_getMethodImplementation(self, @selector(package)), "@:");
		}
	}
}

- (NSString *)package {
	return [self getField:NSStringFromSelector(_cmd)];
}

- (NSString *)getField:(NSString *)field {
	return _rawPackage[field];
}

- (Database *)database {
	return Database.sharedInstance;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@ (%@)>", NSStringFromClass(self.class), self.package, self.version];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict source:(Source *)source {
	if (source && dict && (self = [super init])) {
		_source = source;
		_rawPackage = dict;
		_dependencies = [dict[@"depends"] componentsSeparatedByString:@", "];
		_conflicts = [dict[@"conflicts"] componentsSeparatedByString:@", "];
		NSMutableArray<NSString *> *descriptionLines = [dict[@"description"] componentsSeparatedByString:@"\n"].mutableCopy;
		switch (descriptionLines.count) {
			case 0:
				break;
			case 1: 
				_shortDescription = _longDescription = descriptionLines[0];
				break;
			default:
				_shortDescription = descriptionLines[0];
				[descriptionLines removeObjectAtIndex:0];
				_longDescription = [descriptionLines componentsJoinedByString:@"\n"];
				break;
		}
		return self;
	}
	return nil;
}

@end