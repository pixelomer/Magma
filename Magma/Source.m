#import "Source.h"
#import "DPKGParser.h"
#import "Package.h"
#import <Compression/Compression.h>
#import "Database.h"

@implementation Source

- (instancetype)initWithBaseURL:(NSString *)rawBaseURL architecture:(NSString *)arch distribution:(NSString *)distribution components:(NSString *)components {
	if (!rawBaseURL) return nil;
	NSURL *baseURL = [NSURL URLWithString:rawBaseURL];
	if (!baseURL) return nil;
	self = [super init];
	_baseURL = baseURL;
	_architecture = arch;
	_distribution = distribution ?: @"./";
	_components = (components.length > 0) ? [components componentsSeparatedByString:@" "] : nil;
	if (_components.count == 0) _components = nil;
	return self;
}

- (void)deleteFiles {
	_packages = nil;
	[NSFileManager.defaultManager
		removeItemAtPath:[Database.class releaseFilePathForSource:self]
		error:nil
	];
	[NSFileManager.defaultManager
		removeItemAtPath:[Database.class packagesFilePathForSource:self]
		error:nil
	];
}

- (void)setRawPackagesFile:(NSString *)rawPackagesFile {
	_rawPackagesFile = rawPackagesFile;
	[_rawPackagesFile
	 	writeToFile:[Database.class packagesFilePathForSource:self]
	 	atomically:YES
	 	encoding:NSUTF8StringEncoding
	 	error:nil
	];
	NSMutableArray *packages = [NSMutableArray new];
	NSArray *lines = [rawPackagesFile componentsSeparatedByString:@"\n"];
	NSUInteger scanned = 0;
	NSUInteger startIndex = 0;
	NSUInteger length = 0;
	BOOL lookingForEntry = YES;
	for (NSString *line in lines) {
		BOOL isLineEmpty = ![line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
		if (!isLineEmpty) {
			if (lookingForEntry) lookingForEntry = (startIndex = scanned) && false;
			length += line.length + 1;
		}
		else {
			if (length > 1) {
				length -= 1;
				Package *package = [[Package alloc] initWithRange:NSMakeRange(startIndex, length) source:self];
				if (package) [packages addObject:package];
				lookingForEntry = YES;
			}
			length = 0;
		}
		scanned += line.length + 1;
	}
	if (length > 0) {
		Package *package = [[Package alloc] initWithRange:NSMakeRange(startIndex, length) source:self];
		[packages addObject:package];
	}
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
	_packages = packages;
	packages = nil;
}

- (NSString *)origin {
	return _parsedReleaseFile[@"origin"];
}

- (NSString *)sourcesListEntryWithComponents:(BOOL)includeComponents {
	return [NSString stringWithFormat:@"deb %@ %@%@",
		[_baseURL absoluteString],
		_distribution,
		(includeComponents && _components) ? ([@" " stringByAppendingString:([_components componentsJoinedByString:@" "] ?: @"")]) : @""
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

+ (NSString *)extractPackagesFileData:(NSData *)data usingAlgorithm:(PackagesAlgorithm)algorithm {
	if ([algorithm isEqualToString:PackagesAlgorithmBZip2]) {
		return [[NSString alloc] initWithData:[BZipCompression decompressedDataWithData:data error:nil] encoding:NSUTF8StringEncoding];
	}
	else if ([algorithm isEqualToString:PackagesAlgorithmGZ]) {
		return [[NSString alloc] initWithData:[data gunzippedData] encoding:NSUTF8StringEncoding];
	}
	else if ([algorithm isEqualToString:PackagesAlgorithmXZ]) {
		// FIX ME
	}
	return nil;
}

// Example:
//   (
//     "main" = (
//       "bz2" = ".../main/binary-arch/Packages.bz2",
//       "gz" = ...
//     ),
//     "non-free" = (
//       "bz2" = ".../non-free/binary-arch/Packages.bz2",
//       "gz" = ...
//     ),
//     ...
//   )
- (NSDictionary<NSString *, NSDictionary<PackagesAlgorithm, NSURL *> *> *)possiblePackagesFileURLs {
	if (!_components) {
		return @{
			@"main" : @{
				PackagesAlgorithmBZip2 : [self.filesURL URLByAppendingPathComponent:@"Packages.bz2"],
				PackagesAlgorithmGZ : [self.filesURL URLByAppendingPathComponent:@"Packages.gz"],
				PackagesAlgorithmXZ : [self.filesURL URLByAppendingPathComponent:@"Packages.xz"]
			}
		};
	}
	NSMutableDictionary *returnValue = [NSMutableDictionary new];
	for (NSString *component in _components) {
		NSURL *packagesFileURLParent = [[self.filesURL URLByAppendingPathComponent:component] URLByAppendingPathComponent:[@"binary-" stringByAppendingString:_architecture]];
		returnValue[component] = @{
			PackagesAlgorithmBZip2 : [packagesFileURLParent URLByAppendingPathComponent:@"Packages.bz2"],
			PackagesAlgorithmGZ : [packagesFileURLParent URLByAppendingPathComponent:@"Packages.gz"],
			PackagesAlgorithmXZ : [packagesFileURLParent URLByAppendingPathComponent:@"Packages.xz"]
		};
	}
	return returnValue.copy;
}

@end
