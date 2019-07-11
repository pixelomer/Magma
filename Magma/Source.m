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

- (NSString *)substringFromPackagesFileInRange:(NSRange)range {
	fseek(_packagesFileHandle, range.location, SEEK_SET);
	char *line = malloc(range.length + 1);
	line[range.length] = 0;
	fread(line, 1, range.length, _packagesFileHandle);
	int error;
	NSString *returnValue = !(error = ferror(_packagesFileHandle)) ? [NSString stringWithUTF8String:line] : NULL;
	if (error) {
		NSLog(@"Error: %s", strerror(error));
	}
	free(line);
	return returnValue;
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
	[self unloadPackagesFile];
	if ((_packagesFileHandle = fopen([Database.class packagesFilePathForSource:self].UTF8String, "r"))) {
		NSMutableArray *packages = [NSMutableArray new];
		NSUInteger scanned = 0;
		NSUInteger startIndex = 0;
		NSUInteger length = 0;
		BOOL lookingForEntry = YES;
		int nextLineStartIndex = 0;
		char *CLine;
		NSString *line;
		while ((CLine = fgetline(nextLineStartIndex, &nextLineStartIndex, _packagesFileHandle)) && (line = @(CLine))) {
			BOOL isLineEmpty = ![line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
			if (!isLineEmpty) {
				if (lookingForEntry) lookingForEntry = (startIndex = scanned) && false;
				length += strlen(CLine) + 1;
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
			scanned += strlen(CLine) + 1;
			free(CLine);
		}
		if (length > 0) {
			Package *package = [[Package alloc] initWithRange:NSMakeRange(startIndex, length) source:self];
			if (package) [packages addObject:package];
		}
		_packages = packages.copy;
		packages = nil;
		NSMutableDictionary<NSString *, NSMutableArray<Package *> *> *sections = [NSMutableDictionary new];
		for (Package *package in _packages) {
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
