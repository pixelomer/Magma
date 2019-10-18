#import "Source.h"
#import "DPKGParser.h"
#import "Package.h"
#import <Compression/Compression.h>
#import "Database.h"
#import "MagmaPreferences.h"

@implementation Source

#define RANGES_HEADER_SIZE 4
static const char *rangesHeader = "MG\x00\x01";

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
	_refreshProgress = nil;
	if (_components.count == 0) _components = nil;
	return self;
}

- (void)setRefreshProgress:(NSProgress *)refreshProgress {
	if (refreshProgress != _refreshProgress) {
		[self willChangeValueForKey:@"refreshProgress"];
		_refreshProgress = refreshProgress;
		[self didChangeValueForKey:@"refreshProgress"];
	}
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
	char *substring = malloc(range.length);
	if (!substring) {
		// Either the range is horribly wrong or the system is out of memory
		return nil;
	}
	@synchronized (fileHandleToken) {
		long oldPos = ftell(_packagesFileHandle);
		fseek(_packagesFileHandle, range.location, SEEK_SET);
		fread(substring, 1, range.length, _packagesFileHandle);
		fseek(_packagesFileHandle, oldPos, SEEK_SET);
	}
    if (substring) {
        NSData *data = [NSData dataWithBytes:substring length:range.length];
        if (!encodingPt || !*encodingPt) {
            NSStringEncoding encoding = [NSString stringEncodingForData:data encodingOptions:nil convertedString:&result usedLossyConversion:nil];
            if (result && encodingPt) *encodingPt = encoding;
        }
        else {
            result = [[NSString alloc] initWithData:data encoding:*encodingPt];
        }
    }
	free(substring);
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
		NSMutableSet *packages = nil;
		NSString *rangesFilePath = [packagesFilePath stringByAppendingString:@"_ranges"];
		FILE *rangesFileHandle = fopen(rangesFilePath.UTF8String, "r");
		if (rangesFileHandle) {
			uint8_t header[4];
			header[0] = 0; // Just in case
			fread(header, 1, sizeof(header), rangesFileHandle);
			if (memcmp(header, rangesHeader, 4)) {
				fclose(rangesFileHandle);
				unlink(rangesFilePath.UTF8String);
				rangesFileHandle = NULL;
			}
		}
		if (rangesFileHandle) {
			/*--[Reload algorithm]------------------------------*/
			/* This algorithm makes use of the _ranges file     */
			/* to parse the package entries at the specified    */
			/* locations. This algorithm is much faster since   */
			/* it doesn't need to read the entire file byte by  */
			/* byte just to find where the entries are.         */
			/*--------------------------------------------------*/
			fseek(rangesFileHandle, 0, SEEK_END);
			_refreshProgress.completedUnitCount = 0;
			long packageCount = ((ftell(rangesFileHandle)-RANGES_HEADER_SIZE) / (sizeof(uint32_t)*3));
			packages = [NSMutableSet setWithCapacity:packageCount];
			_refreshProgress.totalUnitCount = packageCount;
			fseek(rangesFileHandle, RANGES_HEADER_SIZE, SEEK_SET);
			while (1) {
				@autoreleasepool {
					uint32_t buffer[3];
					if (fread(buffer, sizeof(uint32_t), 3, rangesFileHandle) != 3) break;
					NSStringEncoding encoding = (NSStringEncoding)buffer[2];
					Package *package = [Package alloc];
					package.encoding = encoding;
					package = [package initWithRange:NSMakeRange(buffer[0], buffer[1]) source:self];
					if (package) [packages addObject:package];
				}
			}
			fclose(rangesFileHandle);
		}
		else {
			/*--[Discovery algorithm]-------------------------*/
			/* This algorithm reads the whole Packages file   */
			/* and creates Package objects. This algorithm    */
			/* is rather slow. Right after this is complete,  */
			/* [Source createRangesFile] should be called     */
			/* to create a _ranges file which is used by the  */
			/* reload algorithm, which is much faster.        */
			/*------------------------------------------------*/
			packages = [NSMutableSet new];
			NSUInteger startIndex = 0;
			NSUInteger length = 0;
			char *cline = NULL;
			size_t nread = 0;
			if (_refreshProgress) {
				{
					unsigned char nl_counter = 0;
					int c = -1;
					uint64_t totalUnitCount = 1;
					do {
						c = getc(_packagesFileHandle);
						switch (c) {
							case '\n':
								if (nl_counter <= 1) nl_counter++;
							case ' ':
							case '\t':
								break;
							default:
								if (nl_counter >= 2) totalUnitCount++;
								nl_counter = 0;
						}
					}
					while (c != -1);
					_refreshProgress.completedUnitCount = 0;
					_refreshProgress.totalUnitCount = totalUnitCount;
				}
				fseek(_packagesFileHandle, 0, SEEK_SET);
			}
			while (getline(&cline, &nread, _packagesFileHandle) != -1) {
				if (!strcmp(cline, "\n")) {
					@autoreleasepool {
						@try {
							_refreshProgress.completedUnitCount++;
							if (length) {
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
								if (package) [packages addObject:package];
							}
							startIndex += length + 1;
							length = 0;
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
		_packages = packages.allObjects.copy;
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
	if (!rangesFile || !fwrite(rangesHeader, RANGES_HEADER_SIZE, 1, rangesFile)) return;
	_refreshProgress.completedUnitCount = 0;
	_refreshProgress.totalUnitCount = _packages.count;
	for (Package *package in _packages) {
		_refreshProgress.completedUnitCount++;
		NSRange range = package.range;
		uint32_t buffer[3] = { (uint32_t)range.location, (uint32_t)range.length, (uint32_t)package.encoding };
		fwrite(buffer, 1, sizeof(buffer), rangesFile);
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
			@"origin",
			@"architectures"
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
		_supportedArchitectures = [filteredReleaseFile[@"architectures"] componentsSeparatedByString:@" "];
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
