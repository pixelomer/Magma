#import "Source.h"
#import "DPKGParser.h"
#import "Package.h"
#import <Compression/Compression.h>
#import "Database.h"

// FRIENDLY REMINDER: free() the returned pointer once you are done with it.
static char *fgetline(int startIndex, int *nextLineStartIndex, FILE *file) {
	int bufferSize = 1;
	unsigned long previousLength = 0;
	char *buffer = malloc(bufferSize);
	buffer[0] = 0;
	do {
		fseek(file, startIndex, SEEK_SET);
		previousLength = strlen(buffer);
		bufferSize += 10;
		buffer = realloc(buffer, bufferSize);
		fgets(buffer, bufferSize, file);
		if (ferror(file) || feof(file)) {
			return NULL;
		}
	} while (strlen(buffer) != previousLength);
	if (nextLineStartIndex && buffer) {
		*nextLineStartIndex = startIndex + (int)strlen(buffer);
	}
	if (buffer) {
		unsigned long stringLength = strlen(buffer);
		if (buffer[stringLength - 1] == '\n') {
			buffer[stringLength - 1] = 0;
		}
	}
	return buffer;
}

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

- (void)unloadPackagesFile {
	_packages = nil;
	_sections = nil;
	if (_packagesFileHandle) {
		fclose(_packagesFileHandle);
		_packagesFileHandle = NULL;
	}
}

- (NSString *)substringFromPackagesFileInRange:(NSRange)range encoding:(NSStringEncoding *)encodingPt {
	char *line = malloc(range.length + 1);
	line[range.length] = 0;
	fseek(_packagesFileHandle, range.location, SEEK_SET);
	fread(line, 1, range.length, _packagesFileHandle);
	NSString *result = nil;
	if (ferror(_packagesFileHandle)) {
		NSLog(@"Failed to get a substring from the Packages file with range: %@", NSStringFromRange(range));
	}
	else {
		if (!encodingPt || !*encodingPt) {
			NSStringEncoding encoding = [NSString stringEncodingForData:[NSData dataWithBytes:line length:range.length] encodingOptions:nil convertedString:&result usedLossyConversion:nil];
			if (!encoding) NSLog(@"Failed to find encoding for range %@ in %@", NSStringFromRange(range), self);
			if (encodingPt) *encodingPt = encoding;
		}
		else {
			result = [NSString stringWithCString:line encoding:*encodingPt];
		}
	}
	free(line);
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

- (void)reloadPackagesFileUsingArrayOfRanges:(NSArray *)array startValue:(short)start increment:(short)increment outputArray:(NSMutableArray *)output {
	for (NSInteger i = start; i < array.count; i+=increment) {
		@autoreleasepool {
			NSString *rangeString = [array[i] stringByAppendingString:@"}"];
			NSRange range = NSRangeFromString(rangeString);
			Package *package = [[Package alloc] initWithRange:range source:self];
			if (package) [output addObject:package];
		}
	}
}

- (void)reloadPackagesFile {
	[self unloadPackagesFile];
	NSString *packagesFilePath = [Database.class packagesFilePathForSource:self];
	if ((_packagesFileHandle = fopen(packagesFilePath.UTF8String, "r"))) {
		NSMutableArray *packages = [NSMutableArray new];
		NSString *rangeFilePath = [packagesFilePath stringByAppendingString:@"_ranges"];
		NSString *rangeFileContents;
		if ((rangeFileContents = [NSString stringWithContentsOfFile:rangeFilePath encoding:NSASCIIStringEncoding error:nil])) {
			NSArray *fileComponents = [rangeFileContents componentsSeparatedByString:@"}"];
			NSOperationQueue *queue = [NSOperationQueue new];
			NSMutableArray *outputs = [NSMutableArray new];
			short increment = 4;
			queue.maxConcurrentOperationCount = increment;
			for (short i = 0; i <= increment; i++) {
				NSMutableArray *output = [NSMutableArray new];
				[outputs addObject:output];
				SEL selector = @selector(reloadPackagesFileUsingArrayOfRanges:startValue:increment:outputArray:);
				NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
				inv.selector = selector;
				inv.target = self;
				[inv setArgument:&fileComponents atIndex:2];
				[inv setArgument:&i atIndex:3];
				[inv setArgument:&increment atIndex:4];
				[inv setArgument:&output atIndex:5];
				NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithInvocation:inv];
				[queue addOperation:operation];
			}
			queue.suspended = NO;
			[queue waitUntilAllOperationsAreFinished];
			for (NSArray *output in outputs) {
				[packages addObjectsFromArray:output];
			}
		}
		else {
			FILE *rangeFile = fopen(rangeFilePath.UTF8String, "w");
			NSUInteger scanned = 0;
			NSUInteger startIndex = 0;
			NSUInteger length = 0;
			BOOL lookingForEntry = YES;
			int nextLineStartIndex = 0;
			char *CLine;
			NSString *line;
#define addPackageWithRange(_range) { Package *package = [[Package alloc] initWithRange:_range source:self]; if (package) { [packages addObject:package]; if (rangeFile) { NSString *rangeString = NSStringFromRange(package.range); if (rangeString) fwrite(rangeString.UTF8String, 1, strlen(rangeString.UTF8String), rangeFile); if (ferror(rangeFile)) { fclose(rangeFile); rangeFile = NULL; [NSFileManager.defaultManager removeItemAtPath:rangeFilePath error:nil]; } } } }
			while ((CLine = fgetline(nextLineStartIndex, &nextLineStartIndex, _packagesFileHandle))) {
				@autoreleasepool {
					line = [NSString stringWithCString:CLine encoding:NSISOLatin1StringEncoding];
					if (!line) { free(CLine); break; }
					BOOL isLineEmpty = ![line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
					if (!isLineEmpty) {
						if (lookingForEntry) lookingForEntry = (startIndex = scanned) && false;
						length += strlen(CLine) + 1;
					}
					else {
						if (length > 1) {
							length -= 1;
							addPackageWithRange(NSMakeRange(startIndex, length));
							lookingForEntry = YES;
						}
						length = 0;
					}
					scanned += strlen(CLine) + 1;
					free(CLine);
				}
			}
			if (length > 0) addPackageWithRange(NSMakeRange(startIndex, length));
			if (rangeFile) fclose(rangeFile);
		}
#undef addPackage
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
