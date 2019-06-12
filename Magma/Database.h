#import <Foundation/Foundation.h>

@class Source;

@interface Database : NSObject {
	BOOL _isLoaded;
	int highestRepoID;
	NSMutableDictionary<NSString *, Source *> *sources;
}
// Configuration:
// Use these methods to configure how the database will be loaded. These methods can only be called before calling +[Database sharedInstance].
+ (void)setWorkingDirectory:(NSString *)newLocation;

// Initialization:
// Calling +[Database sharedInstance] for the first time will initialize the singleton Database object.
+ (instancetype)sharedInstance;

// Usage:
// Use these methods to access/modify information in the database.
- (BOOL)isLoaded;
- (void)startLoadingDataIfNeeded;
- (NSArray *)sources;
- (void)removeSource:(Source *)source;
- (void)addSourceWithBaseURL:(NSString *)baseURL distribution:(NSString *)dist components:(NSString *)components;
- (void)addSourceWithURL:(NSString *)baseURL;
@end