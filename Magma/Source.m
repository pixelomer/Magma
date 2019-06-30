#import "Source.h"
#import "DPKGParser.h"
#import "Package.h"

@implementation Source

- (instancetype)initWithBaseURL:(NSString *)rawBaseURL distribution:(NSString *)distribution components:(NSString *)components {
	if (!rawBaseURL) return nil;
	NSURL *baseURL = [NSURL URLWithString:rawBaseURL];
	if (!baseURL) return nil;
	self = [super init];
	_baseURL = baseURL;
	_distribution = distribution ?: @"./";
	_components = (components.length > 0) ? [components componentsSeparatedByString:@" "] : nil;
	if (_components.count == 0) _components = nil;
	return self;
}

- (NSString *)sourcesListEntryWithComponents:(BOOL)includeComponents {
	return [NSString stringWithFormat:@"deb %@ %@%@",
		[_baseURL absoluteString],
		_distribution,
		includeComponents ? ([@" " stringByAppendingString:([_components componentsJoinedByString:@" "] ?: @"")]) : @""
	];
}

- (void)setParsedReleaseFile:(NSDictionary *)parsedReleaseFile {
	if (!parsedReleaseFile) {
		_rawReleaseFile = nil;
		_parsedReleaseFile = nil;
	}
	else {
		NSMutableArray *reversedReleaseFileComponents = [NSMutableArray new];
		for (NSString *field in parsedReleaseFile) {
			NSString *value = parsedReleaseFile[field];
			[reversedReleaseFileComponents addObject:[NSString stringWithFormat:@"%@: %@", field, [value stringByReplacingOccurrencesOfString:@"\n" withString:@"\n  "]]];
		}
		_rawReleaseFile = [reversedReleaseFileComponents componentsJoinedByString:@"\n"];
		_parsedReleaseFile = parsedReleaseFile;
	}
}

- (void)setPackages:(NSArray<Package *> *)packages {
	if (packages) {
		_packages = packages;
		NSMutableDictionary<NSString *, NSMutableArray<Package *> *> *sections = [NSMutableDictionary new];
		for (Package *package in packages) {
			NSString *section = package.section ?: @"Other";
			if (sections[section]) {
				[sections[section] addObject:package];
			}
			else {
				sections[section] = @[package].mutableCopy;
			}
		}
		for (NSString *key in sections.allKeys.copy) {
			sections[key] = sections[key].copy;
		}
		_sections = sections.copy;
	}
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ \"%@\">", NSStringFromClass(self.class), [self sourcesListEntryWithComponents:YES]];
}

- (void)setLastRefresh:(NSDate *)lastRefresh {
	_lastRefresh = lastRefresh;
}

- (void)setIsRefreshing:(BOOL)isRefreshing {
	_isRefreshing = isRefreshing;
}

- (void)setRawReleaseFile:(NSString *)rawReleaseFile {
	NSDictionary *parsedReleaseFile = [DPKGParser parsePackageEntry:rawReleaseFile error:nil];
	_rawReleaseFile = (parsedReleaseFile ? rawReleaseFile : nil);
	_parsedReleaseFile = parsedReleaseFile;
}

// Example URL: http://apt.thebigboss.org/repofiles/cydia/dists/stable/main/binary-iphoneos-arm
- (NSURL *)filesURL {
	NSURL *repoFilesURL = _baseURL;
	if (_components) {
		repoFilesURL = [[repoFilesURL URLByAppendingPathComponent:@"dists"] URLByAppendingPathComponent:_distribution];
	}
	return repoFilesURL;
}

- (NSURL *)releaseFileURL {
	NSURL *releaseFileURL = [self.filesURL URLByAppendingPathComponent:@"Release"];
	return releaseFileURL;
}

- (NSURL *)packagesFileURL {
	NSURL *packagesFileURLParent = self.filesURL;
	if (_components) {
		packagesFileURLParent = [[packagesFileURLParent URLByAppendingPathComponent:_components[0]] URLByAppendingPathComponent:@"binary-iphoneos-arm"];
	}
	return [packagesFileURLParent URLByAppendingPathComponent:@"Packages.bz2"];
}

- (NSURL *)iconURL {
	return [_baseURL URLByAppendingPathComponent:@"CydiaIcon.png"];
}

@end