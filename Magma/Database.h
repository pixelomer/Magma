#import <Foundation/Foundation.h>

// Any object from that repository should be released
#define DatabaseDidRemoveSource @"com.pixelomer.magma/DatabaseDidRemoveSource"

// New objects from that repository should be loaded
#define DatabaseDidAddSource @"com.pixelomer.magma/DatabaseDidAddSource"

// It is now safe to read/write
#define DatabaseDidLoad @"com.pixelomer.magma/DatabaseDidLoad"

// Handle reloads
#define SourceDidStartRefreshing @"com.pixelomer.magma/SourceDidStartRefreshing"
#define SourceDidStopRefreshing @"com.pixelomer.magma/SourceDidStopRefreshing"
#define DatabaseDidStartRefreshingSources @"com.pixelomer.magma/DatabaseDidStartRefreshingSources"
#define DatabaseDidFinishRefreshingSources @"com.pixelomer.magma/DatabaseDidFinishRefreshingSources"
#define DatabaseDidFinishReloadingRemotePackages @"com.pixelomer.magma/DatabaseDidFinishReloadingRemotePackages"

@class Source;
@class Package;

@interface Database : NSObject<NSURLSessionDownloadDelegate> {
	BOOL _isLoading;
	BOOL _isLoaded;
	int highestRepoID;
	NSMutableDictionary<NSString *, Source *> *sources;
	NSMutableDictionary<NSNumber *, NSMutableDictionary<NSString *, id> *> *sourcesPlist;
}

// Initialization:
// Calling +[Database sharedInstance] for the first time will initialize the singleton Database object.
+ (instancetype)sharedInstance;
// Call -[Database startLoadingDataIfNeeded] after creating the shared instance to load the existing data from the filesystem.
- (void)startLoadingDataIfNeeded;

// Usage:
// Use these methods to access/modify information in the database.
@property (nonatomic, readonly, assign) BOOL isRefreshing;
@property (nonatomic, readonly, strong) NSOperationQueue *refreshQueue;
@property (nonatomic, readonly, copy) NSArray<Package *> *sortedRemotePackages;
+ (NSString *)sourcesPlistPath;
+ (NSString *)listsDirectoryPath;
+ (NSString *)packagesFilePathForSource:(Source *)source;
+ (NSString *)releaseFilePathForSource:(Source *)source;
- (Package *)packageWithIdentifier:(NSString *)identifier;
- (BOOL)isLoaded;
- (Source *)addPPA:(NSString *)ppa distribution:(NSString *)dist architecture:(NSString *)architecture;
- (NSArray *)sources;
- (void)removeSource:(Source *)source;
- (Source *)addSourceWithBaseURL:(NSString *)baseURL architecture:(NSString *)arch distribution:(NSString *)dist components:(NSString *)components;
- (Source *)addSourceWithURL:(NSString *)baseURL architecture:(NSString *)arch;
- (void)startRefreshingSources;

@end
