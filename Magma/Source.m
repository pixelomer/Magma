#import "Source.h"
#import "DPKGParser.h"
#import "Package.h"
#import <Compression/Compression.h>
#import "Database.h"
#import "MagmaPreferences.h"

@implementation Source

- (instancetype)initWithBaseURL:(NSString *)rawBaseURL architecture:(NSString *)arch distribution:(NSString *)distribution components:(NSString *)components {
	if (!rawBaseURL) return nil;
	NSURL *baseURL = [NSURL URLWithString:rawBaseURL];
	if (!baseURL) return nil;
	self = [super init];
	fileHandleToken = [NSObject new];
	_baseURL = baseURL;
	_architecture = arch;
	_distribution = distribution ?: @"./";
	_components = (components.length > 0) ? [components componentsSeparatedByString:@" "] : nil;
	if (_components.count == 0) _components = nil;
	return self;
}

- (void)unloadPackagesFile {
	_packages = nil;
	_sections = nil;
	if (_packagesFileHandle) {
		fclose(_packagesFileHandle);
		_packagesFileHandle = NULL;
	}
}

- (NSString *)substringFromPackagesFileInRange:(NSRange)range encoding:(NSStringEncoding *)encodingPt {
	NSString *result = nil;
	char *asciiString = malloc(range.length);
	@synchronized (fileHandleToken) {
		long oldPos = ftell(_packagesFileHandle);
		fseek(_packagesFileHandle, range.location, SEEK_SET);
		fread(asciiString, 1, range.length, _packagesFileHandle);
		fseek(_packagesFileHandle, oldPos, SEEK_SET);
	}
	if (!encodingPt || !*encodingPt) {
		NSStringEncoding encoding = [NSString stringEncodingForData:[NSData dataWithBytes:asciiString length:range.length] encodingOptions:nil convertedString:&result usedLossyConversion:nil];
		if (result && encodingPt) *encodingPt = encoding;
	}
	else {
		result = [NSString stringWithCString:asciiString encoding:*encodingPt];
	}
	free(asciiString);
	return result;
}

- (void)deleteFiles {
	[self unloadPackagesFile];
	[NSFileManager.defaultManager
		removeItemAtPath:[Database.class releaseFilePathForSource:self]
		error:nil
	];
	[NSFileManager.defaultManager
		removeItemAtPath:[Database.class packagesFilePathForSource:self]
		error:nil
	];
}

- (void)reloadPackagesFile {
	NSDate *start = [NSDate date];
	[self unloadPackagesFile];
	NSString *packagesFilePath = [Database.class packagesFilePathForSource:self];
	if ((_packagesFileHandle = fopen(packagesFilePath.UTF8String, "r"))) {
		NSMutableArray *packages = [NSMutableArray new];
		FILE *rangesFileHandle = fopen([packagesFilePath stringByAppendingString:@"_ranges"].UTF8String, "r");
		if (rangesFileHandle) {
			char *cinfo = nil;
			size_t nread = 0;
			while (getline(&cinfo, &nread, rangesFileHandle) != -1) {
				@autoreleasepool {
					NSString *info = [NSString stringWithCString:cinfo encoding:NSASCIIStringEncoding];
					NSArray *parts = [info componentsSeparatedByString:@"-"];
					if (parts.count >= 2) {
						NSRange range = NSRangeFromString(parts[0]);
						NSStringEncoding encoding = (NSStringEncoding)[(NSString *)parts[1] longLongValue];
						Package *package = [Package alloc];
						package.encoding = encoding;
						package = [package initWithRange:range source:self];
						if (package) [packages addObject:package];
					}
				}
			}
			fclose(rangesFileHandle);
		}
		else {
			NSUInteger startIndex = 0;
			NSUInteger length = 0;
			char *cline = NULL;
			size_t nread = 0;
			while (getline(&cline, &nread, _packagesFileHandle) != -1) {
				if (!strcmp(cline, "\n")) {
					@autoreleasepool {
						@try {
							Package *package = [Package alloc];
							NSRange range = NSMakeRange(startIndex, length-1);
							if (MagmaPreferences.assumesUTF8) {
								package.encoding = NSUTF8StringEncoding; // Assume UTF-8
								if (![package initWithRange:range source:self]) {
									package.encoding = 0; // This is not UTF-8, try finding the correct encoding
									package = [package initWithRange:range source:self];
								}
							}
							else {
								package = [package initWithRange:range source:self];
							}
							startIndex += length + 1;
							length = 0;
							if (package) [packages addObject:package];
						}
						@catch (NSException *ex) {
							continue;
						}
					}
				}
				else length += strlen(cline);
			}
			if (cline) free(cline);
		}
		_packages = packages.copy;
		packages = nil;
		NSMutableDictionary<NSString *, NSMutableArray<Package *> *> *sections = [NSMutableDictionary new];
		for (Package *package in _packages) {
			NSString *section = package.section ?: @"(unknown)";
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
		sections = nil;
	}
	NSLog(@"Took %f seconds to reload %@", [[NSDate date] timeIntervalSinceDate:start], self);
}

- (void)createRangesFile {
	NSString *finalPath = [[Database.class packagesFilePathForSource:self] stringByAppendingString:@"_ranges"];
	NSString *tmpPath = [finalPath stringByAppendingString:@".tmp"];
	FILE *rangesFile = fopen(tmpPath.UTF8String, "w");
	if (!rangesFile) return;
	for (Package *package in _packages) {
		@autoreleasepool {
			NSRange range = package.range;
			NSString *line = [NSString stringWithFormat:@"%@-%lu\n", NSStringFromRange(range), (unsigned long)package.encoding];
			fwrite(line.UTF8String, 1, strlen(line.UTF8String), rangesFile);
		}
	}
	fclose(rangesFile);
	[NSFileManager.defaultManager moveItemAtPath:tmpPath toPath:finalPath error:nil];
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
		NSArray *allowedKeys = @[
			@"origin"
		];
		NSMutableDictionary *filteredReleaseFile = [NSMutableDictionary new];
		for (NSString *fieldName in parsedReleaseFile) {
			if ([allowedKeys containsObject:fieldName]) {
				filteredReleaseFile[fieldName] = parsedReleaseFile[fieldName];
			}
		}
		[filteredReleaseFile writeToFile:[Database.class releaseFilePathForSource:self] atomically:YES];
		NSMutableArray *reversedReleaseFileComponents = [NSMutableArray new];
		for (NSString *field in filteredReleaseFile) {
			NSString *value = filteredReleaseFile[field];
			[reversedReleaseFileComponents addObject:[NSString stringWithFormat:@"%@: %@", field, [value stringByReplacingOccurrencesOfString:@"\n" withString:@"\n  "]]];
		}
		_rawReleaseFile = [reversedReleaseFileComponents componentsJoinedByString:@"\n"];
		_parsedReleaseFile = filteredReleaseFile.copy;
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
	self.parsedReleaseFile = [DPKGParser parsePackageEntry:rawReleaseFile error:nil];
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

+ (BOOL)extractPackagesFile:(NSString *)inputFilePath toFile:(NSString *)outputFilePath usingAlgorithm:(PackagesAlgorithm)algorithm {
	if ([algorithm isEqualToString:PackagesAlgorithmBZip2]) {
		return [NSData bunzipFile:inputFilePath toFile:outputFilePath];
	}
	else if ([algorithm isEqualToString:PackagesAlgorithmGZ]) {
		return [NSData gunzipFile:inputFilePath toFile:outputFilePath];
	}
	else if ([algorithm isEqualToString:PackagesAlgorithmXZ]) {
		return [NSData extractXZFileAtPath:inputFilePath toFileAtPath:outputFilePath];
	}
	return NO;
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
