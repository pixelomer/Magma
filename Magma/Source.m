#import "Source.h"
#import "DPKGParser.h"

@implementation Source

- (instancetype)initWithBaseURL:(NSString *)rawBaseURL distribution:(NSString *)distribution components:(NSString *)components {
	if (!rawBaseURL) return nil;
	NSURL *baseURL = [NSURL URLWithString:rawBaseURL];
	if (!baseURL) return nil;
	self = [super init];
	_baseURL = baseURL;
	_distribution = distribution ?: @"./";
	_components = [components componentsSeparatedByString:@" "];
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

- (void)setPackages:(NSArray<Package *> *)packages {
	// TODO: Extra operations to set the first discovery date on package
	_packages = packages;
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