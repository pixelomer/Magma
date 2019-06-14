#import <Foundation/Foundation.h>

@interface Source : NSObject {
	BOOL _isRefreshing;
}
@property (nonatomic, readonly, strong) NSURL *baseURL;
@property (nonatomic, readonly, strong) NSString *distribution;
@property (nonatomic, readonly, strong) NSArray<NSString *> *components;
@property (nonatomic, copy, setter=setRawReleaseFile:) NSString *rawReleaseFile;
@property (nonatomic, readonly, copy) NSDictionary *parsedReleaseFile;
@property (nonatomic, assign) int databaseID;
- (BOOL)isRefreshing;
- (instancetype)initWithBaseURL:(NSString *)baseURL distribution:(NSString *)distribution components:(NSString *)components;
- (NSString *)sourcesListEntryWithComponents:(BOOL)includeComponents;
- (void)setRawReleaseFile:(NSString *)rawReleaseFile;
- (NSURL *)releaseFileURL;
- (NSURL *)packagesFileURL;
- (NSURL *)iconURL;
@end