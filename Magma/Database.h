#import <Foundation/Foundation.h>

// Any object from that repository should be released
#define DatabaseDidRemoveSource @"com.pixelomer.magma/DatabaseDidRemoveSource"

// New objects from that repository should be loaded
#define DatabaseDidAddSource @"com.pixelomer.magma/DatabaseDidAddSource"

// It is now safe to read/write
#define DatabaseDidLoad @"com.pixelomer.magma/DatabaseDidLoad"

// Log, show a message, crash, etc.
#define DatabaseDidEncounterAnError @"com.pixelomer.magma/DatabaseDidEncounterAnError"

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

// Configuration:
// Use these methods to configure how the database will be loaded. These methods can only be called before calling +[Database sharedInstance].
+ (void)setWorkingDirectory:(NSString *)newLocation;

// Initialization:
// Calling +[Database sharedInstance] for the first time will initialize the singleton Database object.
+ (instancetype)sharedInstance;

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
- (void)startLoadingDataIfNeeded;
- (NSArray *)sources;
- (void)removeSource:(Source *)source;
- (void)addSourceWithBaseURL:(NSString *)baseURL architecture:(NSString *)arch distribution:(NSString *)dist components:(NSString *)components;
- (void)addSourceWithURL:(NSString *)baseURL architecture:(NSString *)arch;
- (void)startRefreshingSources;

@end
