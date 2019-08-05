#import <Foundation/Foundation.h>

#define PackagesAlgorithmBZip2 @"bz2"
#define PackagesAlgorithmGZ @"gz"
#define PackagesAlgorithmXZ @"xz"

typedef NSString* PackagesAlgorithm;

@class Package;

@interface Source : NSObject {
	NSObject *fileHandleToken;
}
@property (nonatomic, readonly, copy) NSURL *baseURL;
@property (nonatomic, readonly, copy) NSString *distribution;
@property (nonatomic, readonly, copy) NSArray<NSString *> *components;
@property (nonatomic, copy) NSDictionary *parsedReleaseFile;
@property (nonatomic, copy) NSString *rawReleaseFile;
@property (nonatomic, readonly, assign) FILE *packagesFileHandle;
@property (nonatomic, readonly, copy) NSString *architecture;
@property (nonatomic, assign) int databaseID;
@property (nonatomic, readonly, copy) NSDate *lastRefresh;
@property (nonatomic, readonly, assign) BOOL isRefreshing;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSArray<Package *> *> *sections;
@property (nonatomic, readonly, copy) NSArray<Package *> *packages;
+ (BOOL)extractPackagesFile:(NSString *)inputFilePath toFile:(NSString *)outputFilePath usingAlgorithm:(PackagesAlgorithm)algorithm;
- (instancetype)initWithBaseURL:(NSString *)baseURL architecture:(NSString *)arch distribution:(NSString *)distribution components:(NSString *)components;
- (NSString *)sourcesListEntryWithComponents:(BOOL)includeComponents;
- (void)unloadPackagesFile;
- (void)reloadPackagesFile;
- (void)deleteFiles;
- (void)createRangesFile;

/// @brief      Reads the specified range from the Packages file.
/// @warning    This function is not thread-safe.
/// @param      range The range of the string in the Packages file.
/// @param      encodingPt A pointer to an NSStringEncoding variable. If the value is 0, the encoding will be found and written.
///                        Otherwise the existing value will be used as the encoding.
- (NSString *)substringFromPackagesFileInRange:(NSRange)range encoding:(NSStringEncoding *)encodingPt;

- (NSURL *)releaseFileURL;
- (NSDictionary<NSString *, NSDictionary<PackagesAlgorithm, NSURL *> *> *)possiblePackagesFileURLs;
@end

@interface Source(CommonFields)
- (NSString *)origin;
@end
