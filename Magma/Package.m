#import "Package.h"
#import "Database.h"
#import <objc/runtime.h>
#import "Source.h"
#import <SUStandardVersionComparator/SUStandardVersionComparator.h>

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
			@"name",
			@"section",
			@"sha512"
		];
		for (NSString *selectorString in selectors) {
			SEL selector = NSSelectorFromString(selectorString);
			class_addMethod(self, selector, class_getMethodImplementation(self, @selector(package)), "@@:");
		}
	}
}

- (BOOL)isEqual:(Package *)object {
	return [object isKindOfClass:[Package class]] && ([object compare:self] == NSOrderedSame);
}

+ (NSArray<Package *> *)createPackagesUsingArray:(NSArray<NSDictionary<NSString *, NSString *> *> *)array source:(Source *)source {
	NSMutableArray *packages = [NSMutableArray new];
	for (NSDictionary *dict in array) {
		[packages addObject:[[Package alloc] initWithDictionary:dict source:source]];
	}
	return packages.copy;
}

- (NSArray *)tags {
	return [self[@"tag"] componentsSeparatedByString:@" "];
}

- (NSComparisonResult)compare:(Package *)package {
	NSComparisonResult IDComparisonResult = [self.package compare:package.package];
	return (
		IDComparisonResult == NSOrderedSame ?
		[SUStandardVersionComparator compareVersion:self.version toVersion:package.version] :
		IDComparisonResult
	);
#undef IDForPackage
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

- (void)setFirstDiscovery:(NSDate *)firstDiscovery {
	_firstDiscovery = firstDiscovery;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict source:(Source *)source {
	if (dict && (self = [super init])) {
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
		if ((_source = source) && dict[@"filename"]) {
			_debURL = [source.baseURL URLByAppendingPathComponent:dict[@"filename"]];
		}
		return self;
	}
	return nil;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
	return _rawPackage[key.lowercaseString];
}

- (NSString *)rawPackagesEntry {
	if (_rawPackagesEntry) return _rawPackagesEntry;
	NSMutableString *string = [NSMutableString new];
	for (NSString *key in _rawPackage) {
		NSString *value = _rawPackage[key];
		[string appendFormat:@"%@: %@\n", key, [value stringByReplacingOccurrencesOfString:@"\n" withString:@"\n  "]];
	}
	return _rawPackagesEntry = [string copy];
}

@end
