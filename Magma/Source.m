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
		includeComponents ? ([_components componentsJoinedByString:@" "] ?: @"") : @""
	];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ \"%@\">", NSStringFromClass(self.class), [self sourcesListEntryWithComponents:YES]];
}

- (BOOL)isRefreshing {
	return _isRefreshing;
}

- (void)setIsRefreshing:(BOOL)isRefreshing {
	_isRefreshing = isRefreshing;
}

- (void)setRawReleaseFile:(NSString *)rawReleaseFile {
	NSDictionary *parsedReleaseFile = [DPKGParser parsePackageEntry:rawReleaseFile error:nil];
	_rawReleaseFile = (parsedReleaseFile ? rawReleaseFile : nil);
	_parsedReleaseFile = parsedReleaseFile;
}

- (NSURL *)repoFilesURL {
	NSURL *repoFilesURL = _baseURL.copy;
	if (_components) {
		// Do some weird stuff
	}
	return repoFilesURL;
}

- (NSURL *)releaseFileURL {
	return [self.repoFilesURL URLByAppendingPathComponent:@"Release"];
}

- (NSURL *)packagesFileURL {
	return [self.repoFilesURL URLByAppendingPathComponent:@"Packages"];
}

- (NSURL *)iconURL {
	return [_baseURL URLByAppendingPathComponent:@"CydiaIcon.png"];
}

@end