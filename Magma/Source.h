#import <Foundation/Foundation.h>

#define PackagesAlgorithmBZip2 @"bz2"
#define PackagesAlgorithmGZ @"gz"
#define PackagesAlgorithmXZ @"xz"

typedef NSString* PackagesAlgorithm;

@class Package;

@interface Source : NSObject
@property (nonatomic, readonly, copy) NSURL *baseURL;
@property (nonatomic, readonly, copy) NSString *distribution;
@property (nonatomic, readonly, copy) NSArray<NSString *> *components;
@property (nonatomic, copy) NSDictionary *parsedReleaseFile;
@property (nonatomic, copy) NSString *rawReleaseFile;
@property (nonatomic, readonly, copy) NSString *architecture;
@property (nonatomic, assign) int databaseID;
@property (nonatomic, readonly, copy) NSDate *lastRefresh;
@property (nonatomic, readonly, assign) BOOL isRefreshing;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSArray<Package *> *> *sections;
@property (nonatomic, readonly, copy) NSArray<Package *> *packages;
+ (NSString *)extractPackagesFileData:(NSData *)data usingAlgorithm:(PackagesAlgorithm)algorithm;
- (instancetype)initWithBaseURL:(NSString *)baseURL distribution:(NSString *)distribution components:(NSString *)components;
- (NSString *)sourcesListEntryWithComponents:(BOOL)includeComponents;
- (NSURL *)releaseFileURL;
- (NSDictionary<PackagesAlgorithm, NSURL *> *)possiblePackagesFileURLs;
- (NSURL *)iconURL;
@end