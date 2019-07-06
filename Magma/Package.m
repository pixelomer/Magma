#import "Package.h"
#import "Database.h"
#import <objc/runtime.h>
#import "DPKGParser.h"
#import "Source.h"
#import <SUStandardVersionComparator/SUStandardVersionComparator.h>

@implementation Package

- (NSString *)rawPackagesEntry {
	return [_source.rawPackagesFile substringWithRange:_range];
}

+ (void)load {
	if ([self class] == [Package class]) {
		NSArray *selectors = @[
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
			class_addMethod(self, selector, class_getMethodImplementation(self, @selector(author)), "@@:");
		}
	}
}

- (BOOL)isEqual:(Package *)object {
	return [object isKindOfClass:[Package class]] && ([object compare:self] == NSOrderedSame);
}

// FIXME: New system
+ (NSArray<Package *> *)createPackagesUsingArray:(NSArray<NSArray<NSNumber *> *> *)array source:(Source *)source {
	NSMutableArray *packages = [NSMutableArray new];
	for (NSArray<NSNumber *> *rangeArray in array) {
		[packages addObject:[[Package alloc] initWithRange:NSMakeRange(rangeArray[0].unsignedIntegerValue, rangeArray[1].unsignedIntegerValue) source:source]];
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

- (NSString *)author {
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

- (void)parse {
	NSError *error;
	NSString *rawPackagesEntry = self.rawPackagesEntry;
	_rawPackage = _rawPackage ?: [DPKGParser parsePackageEntry:rawPackagesEntry error:&error];
	NSLog(@"%@", error);
}

- (instancetype)initWithRange:(NSRange)range source:(Source *)source {
	if ((self = [super init])) {
		_source = source;
		_range = range;
		NSArray *requiredValues = [DPKGParser findFirstLinesForFields:@[@"package", @"version", @"description", @"section"] inString:source.rawPackagesFile range:range];
		for (short i = 0; i <= 2; i++) {
			if ([requiredValues[i] isKindOfClass:[NSNull class]]) {
				return nil;
			}
		}
		_package = requiredValues[0];
		_version = requiredValues[1];
		_shortDescription = requiredValues[2];
		_section = [requiredValues[3] isKindOfClass:[NSString class]] ? requiredValues[3] : nil;
	}
	return self;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
	return _rawPackage[key.lowercaseString];
}

@end
