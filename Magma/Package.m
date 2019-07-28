#import "Package.h"
#import "Database.h"
#import <objc/runtime.h>
#import "DPKGParser.h"
#import "Source.h"
#import <SUStandardVersionComparator/SUStandardVersionComparator.h>

@implementation Package

- (NSString *)rawPackagesEntry {
	return [_source substringFromPackagesFileInRange:_range encoding:&_encoding];
}

+ (NSArray *)latestSortedPackagesFromPackageArray:(NSArray *)array {
	NSMutableDictionary *filteredPackages = [NSMutableDictionary new];
	for (Package *package in array) {
		NSString *ID = package.package;
		if (!filteredPackages[ID] || ([package compare:filteredPackages[ID]] == NSOrderedDescending)) {
			filteredPackages[ID] = package;
		}
	}
	return [filteredPackages.allValues sortedArrayUsingSelector:@selector(compare:)];
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

- (BOOL)parse {
	if (!_rawPackage) {
		NSError *error;
		NSString *rawPackagesEntry = self.rawPackagesEntry;
		if ((_rawPackage = [DPKGParser parsePackageEntry:rawPackagesEntry error:&error])) {
			_debURL = [_source.baseURL URLByAppendingPathComponent:_rawPackage[@"filename"]];
			NSMutableArray *fullDescription = [_rawPackage[@"description"] componentsSeparatedByString:@"\n"].mutableCopy;
			_shortDescription = fullDescription.firstObject;
			if (fullDescription.count > 1) {
				[fullDescription removeObjectAtIndex:0];
				for (NSInteger i = 0; i < fullDescription.count; i++) {
					NSString *value = [fullDescription[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					if ([value isEqualToString:@"."]) fullDescription[i] = @"";
				}
			}
			_longDescription = [fullDescription componentsJoinedByString:@"\n"];
			_section = _version = _package = nil;
			return YES;
		}
		else {
			NSLog(@"Parse failure: %@", error);
		}
	}
	else {
		return YES;
	}
	return NO;
}

- (NSString *)version {
	return _rawPackage[@"version"] ?: _version;
}

- (NSString *)section {
	return _rawPackage[@"section"] ?: _section;
}

- (NSString *)package {
	return _rawPackage[@"package"] ?: _package;
}

- (instancetype)initWithRange:(NSRange)range source:(Source *)source {
	if ((self = [super init])) {
		_source = source;
		_range = range;
		NSArray *requiredValues = [DPKGParser findFirstLinesForFields:@[@"package", @"version", @"description", @"section"] inString:self.rawPackagesEntry];
		for (short i = 0; i <= 2; i++) {
			if ([requiredValues[i] isKindOfClass:[NSNull class]]) {
				return nil;
			}
		}
		_package = requiredValues[0];
		_version = requiredValues[1];
		_longDescription = _shortDescription = requiredValues[2];
		_section = [requiredValues[3] isKindOfClass:[NSString class]] ? requiredValues[3] : nil;
	}
	return self;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
	return _rawPackage[key.lowercaseString];
}

@end
