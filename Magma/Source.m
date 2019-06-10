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
	return self;
}

- (NSString *)sourcesListEntryWithComponents:(BOOL)includeComponents {
	return [NSString stringWithFormat:@"deb %@ %@%@",
		[_baseURL absoluteString],
		_distribution,
		includeComponents ? ([_components componentsJoinedByString:@" "] ?: @"") : @""
	];
}

- (void)setRawReleaseFile:(NSString *)rawReleaseFile {
	NSDictionary *parsedReleaseFile = [DPKGParser parsePackageEntry:rawReleaseFile error:nil];
	if (parsedReleaseFile) {
		_rawReleaseFile = rawReleaseFile;
		_parsedReleaseFile = parsedReleaseFile;
	}
}

@end