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
#define DatabaseDidFinishRefreshingSources @"com.pixelomer.magma/DatabaseDidFinishRefreshingSources"
#define DatabaseDidFinishReloadingLocalPackages @"com.pixelomer.magma/DatabaseDidFinishReloadingLocalPackages"
#define DatabaseDidFinishReloadingRemotePackages @"com.pixelomer.magma/DatabaseDidFinishReloadingRemotePackages"

@class Source;
@class Package;

@interface Database : NSObject {
	BOOL _isLoaded;
	int highestRepoID;
	NSMutableDictionary<NSString *, Source *> *sources;
}

// Configuration:
// Use these methods to configure how the database will be loaded. These methods can only be called before calling +[Database sharedInstance].
+ (void)setWorkingDirectory:(NSString *)newLocation;
+ (NSString *)sourcesPlistPath;
+ (NSString *)listsDirectoryPath;

// Initialization:
// Calling +[Database sharedInstance] for the first time will initialize the singleton Database object.
+ (instancetype)sharedInstance;

// Usage:
// Use these methods to access/modify information in the database.
@property (nonatomic, readonly, assign) BOOL isRefreshing;
@property (nonatomic, readonly, strong) NSOperationQueue *refreshQueue;
@property (nonatomic, readonly, copy) NSArray<Package *> *sortedLocalPackages;
@property (nonatomic, readonly, copy) NSArray<Package *> *sortedRemotePackages;
- (Package *)packageWithIdentifier:(NSString *)identifier;
- (BOOL)isLoaded;
- (void)startLoadingDataIfNeeded;
- (NSArray *)sources;
- (void)removeSource:(Source *)source;
- (void)addSourceWithBaseURL:(NSString *)baseURL distribution:(NSString *)dist components:(NSString *)components;
- (void)addSourceWithURL:(NSString *)baseURL;
- (void)startRefreshingSources;

@end