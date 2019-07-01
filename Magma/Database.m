// TODO: Completely get rid of out-of-sandbox access and switch to using a bunch of plists from using sqlite3

#import "Database.h"
#import <BZipCompression/BZipCompression.h>
#import "Source.h"
#import "DPKGParser.h"
#import "Package.h"

@interface Source(Private)
- (void)setIsRefreshing:(BOOL)isRefreshing;
- (void)setLastRefresh:(NSDate *)lastRefresh;
- (void)setPackages:(NSArray<Package *> *)packages;
@end

@interface Package(Private)
- (void)setFirstDiscovery:(NSDate *)firstDiscovery;
- (void)setIgnoresUpdates:(BOOL)doesIt;
@end

@implementation Database

static Database *sharedInstance;
static NSString *workingDirectory;
static NSArray *paths;

+ (instancetype)alloc {
	return sharedInstance ? nil : [super alloc];
}

+ (instancetype)sharedInstance {
	if (!sharedInstance) {
		if (!workingDirectory) {
			@throw [NSException
				exceptionWithName:NSGenericException
				reason:@"The working directory must be set before calling +[Database sharedInstance]."
				userInfo:nil
			];
		}
		sharedInstance = [self new];
		[sharedInstance startLoadingDataIfNeeded];
	}
	return sharedInstance;
}

+ (void)setWorkingDirectory:(NSString *)newLocation {
	if (!([NSFileManager.defaultManager createDirectoryAtPath:[newLocation stringByAppendingPathComponent:@"lists"] withIntermediateDirectories:YES attributes:nil error:nil] && ([NSFileManager.defaultManager fileExistsAtPath:[newLocation stringByAppendingPathComponent:@"sources.plist"]] || [@{} writeToFile:[newLocation stringByAppendingPathComponent:@"sources.plist"] atomically:YES]))) {
		@throw [NSException
			exceptionWithName:NSInternalInconsistencyException
			reason:@"Failed to prepare the directory. Continuing execution will result in a crash so just crashing now."
			userInfo:nil
		];
	}
	workingDirectory = newLocation.copy;
	paths = @[
		[workingDirectory stringByAppendingPathComponent:@"sources.plist"],
		[workingDirectory stringByAppendingPathComponent:@"lists"]
	];
}

+ (NSString *)sourcesPlistPath {
	return paths.firstObject;
}

+ (NSString *)listsDirectoryPath {
	return paths.lastObject;
}

+ (NSString *)workingDirectory {
	return workingDirectory;
}

- (BOOL)isLoaded {
	return _isLoaded;
}

- (instancetype)init {
	if (self = [super init]) {
		_sortedLocalPackages = @[];
		_sortedRemotePackages = @[];
	}
	return self;
}

- (void)syncFilesForSource:(Source *)source {
	if ([sources.allValues indexOfObjectIdenticalTo:source] != NSNotFound) {
		[source.parsedReleaseFile writeToFile:[self.class releaseFilePathForSource:source] atomically:YES];
		if (source.packages) {
			NSLog(@"if check succeeded.");
			NSMutableDictionary *oldPackagesDictionary = [NSMutableDictionary new];
			NSArray *detailedPackages = [self.class packagesFileForSourceFromDisk:source];
			for (NSArray<NSDictionary *> *packageDetails in detailedPackages) {
				NSString *packageID = packageDetails[1][@"package"];
				NSString *version = packageDetails[1][@"version"];
				NSDate *firstDiscovery = packageDetails[0][@"firstDiscovery"];
				NSString *key = [NSString stringWithFormat:@"%@ %@", packageID, version];
				oldPackagesDictionary[key] = firstDiscovery;
			}
			NSMutableArray *newPackagesFile = [NSMutableArray new];
			NSDate *date = NSDate.date;
			for (Package *newPackage in source.packages) {
				NSString *key = [NSString stringWithFormat:@"%@ %@", newPackage.package, newPackage.version];
				[newPackagesFile addObject:@[
					@{
						@"firstDiscovery" : (oldPackagesDictionary[key] ?: date)
					},
					newPackage.rawPackage
				]];
			}
			NSLog(@"%@", newPackagesFile);
			[newPackagesFile writeToFile:[self.class packagesFilePathForSource:source] atomically:YES];
		}
	}
	else {
		[NSFileManager.defaultManager removeItemAtPath:[self.class releaseFilePathForSource:source] error:nil];
		[NSFileManager.defaultManager removeItemAtPath:[self.class packagesFilePathForSource:source] error:nil];
		[sourcesPlist removeObjectForKey:@(source.databaseID)];
	}
	NSMutableDictionary *serializableSourcesPlist = [NSMutableDictionary new];
	for (NSNumber *NSID in sourcesPlist) {
		NSString *ID = [NSID stringValue];
		serializableSourcesPlist[ID] = sourcesPlist[NSID];
	}
	[serializableSourcesPlist writeToFile:self.class.sourcesPlistPath atomically:YES];
}

- (void)syncFiles {
	for (Source *source in sources.allValues) {
		[self syncFilesForSource:source];
	}
}

+ (NSString *)releaseFilePathForSource:(Source *)source {
	return [self.listsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i_Release.plist", source.databaseID]];
}

+ (NSString *)packagesFilePathForSource:(Source *)source {
	return [self.listsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i_Packages.plist", source.databaseID]];
}

+ (NSDictionary *)releaseFileForSourceFromDisk:(Source *)source {
	return [NSDictionary dictionaryWithContentsOfFile:[self releaseFilePathForSource:source]];
}

+ (NSArray<NSArray<NSDictionary *> *> *)packagesFileForSourceFromDisk:(Source *)source {
	return [NSArray arrayWithContentsOfFile:[self packagesFilePathForSource:source]];
}

- (void)startLoadingDataIfNeeded {
	if (!_isLoaded) {
		if (!workingDirectory) {
			@throw [NSException
				exceptionWithName:NSInternalInconsistencyException
				reason:@"The working directory has to be set before calling this method. Call +[Database setWorkingDirectory:] in order to do so."
				userInfo:nil
			];
		}
		// Load data from the filesystem
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			// Load repositories
			sourcesPlist = [NSMutableDictionary new];
			NSDictionary<NSString *, NSDictionary *> *storedFile = [[NSDictionary alloc] initWithContentsOfFile:self.class.sourcesPlistPath];
			for (NSString *ID in storedFile) {
				NSNumber *NSID = @([ID intValue]);
				sourcesPlist[NSID] = storedFile[ID].mutableCopy;
			}
			for (NSNumber *_sourceID in sourcesPlist.allKeys.copy) {
				Source *source;
				NSDictionary<NSString *, id> *sourceDict = sourcesPlist[_sourceID];
				if ([(NSString *)sourceDict[@"components"] length] > 0) {
					source = [self addSourceWithURL:sourceDict[@"baseURL"] ID:_sourceID];
				}
				else {
					source = [self addSourceWithBaseURL:sourceDict[@"baseURL"] distribution:sourceDict[@"dist"] components:sourceDict[@"components"] ID:_sourceID];
				}
				if (source) {
					source.parsedReleaseFile = [self.class releaseFileForSourceFromDisk:source];
					source.lastRefresh = sourceDict[@"lastRefresh"];
					NSMutableArray *packages = [NSMutableArray new];
					NSArray<NSArray<NSDictionary *> *> *rawPackagesFile = [self.class packagesFileForSourceFromDisk:source];
					for (NSArray *packageInfo in rawPackagesFile) {
						if (packageInfo.count < 2) continue;
						NSDictionary *packageConfiguration = packageInfo[0];
						NSDictionary *parsedControl = packageInfo[1];
						NSDate *firstDiscovery = packageConfiguration[@"firstDiscovery"];
						Package *package = [[Package alloc] initWithDictionary:parsedControl source:source];
						package.firstDiscovery = firstDiscovery;
						if (package) [packages addObject:package];
					}
					source.packages = packages.copy;
				}
			}
			
			// Put packages from all of the sources into one sorted array
			[self reloadRemotePackages];

			_isLoaded = YES;
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidLoad
				object:self
				userInfo:nil
			];
		});
	}
}

- (NSArray *)sources {
	return (id)[sources allValues];
}

- (void)removeSource:(Source *)source {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (_isRefreshing) {
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidEncounterAnError
				object:self
				userInfo:@{ @"error" : @"It is not possible to remove a source while refreshing." }
			];
		}
		BOOL isSourceKnown = NO;
		NSArray<NSString *> *keys = sources.allKeys.copy;
		for (NSString *knownSourceIdentifier in keys) {
			Source *knownSource = sources[knownSourceIdentifier];
			if (knownSource == source) {
				[sources removeObjectForKey:knownSourceIdentifier];
				isSourceKnown = YES;
			}
		}
		if (isSourceKnown) [self syncFilesForSource:source];
		[NSNotificationCenter.defaultCenter
			postNotificationName:DatabaseDidRemoveSource
			object:self
			userInfo:@{ @"source" : source }
		];
	});
}

- (void)addSourceWithURL:(NSString *)baseURL {
	[self addSourceWithBaseURL:baseURL distribution:@"./" components:nil];
}

- (Source *)addSourceWithURL:(NSString *)baseURL ID:(NSNumber *)repoID {
	return [self addSourceWithBaseURL:baseURL distribution:@"./" components:nil ID:repoID];
}

- (void)addSourceWithBaseURL:(NSString *)baseURL distribution:(NSString *)dist components:(NSString *)components {
	if (_isRefreshing) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidEncounterAnError
				object:self
				userInfo:@{ @"error" : @"It is not possible to add a source while refreshing." }
			];
		});
	}
	[self addSourceWithBaseURL:baseURL distribution:dist components:components ID:nil];
}

- (Source *)addIncompleteSource:(Source *)source ID:(NSNumber *)repoID {
	NSString *notificationName = DatabaseDidAddSource;
	NSDictionary *userInfo = @{ @"source" : source };
	id returnValue = source;
	if (!sources[[source sourcesListEntryWithComponents:NO]]) {
		if (repoID) {
			// A repository ID was specified. The repository entry already exists in the database.
			source.databaseID = repoID.intValue;
		}
		else {
			// A repository ID wasn't specified. We need to add the repository entry ourselves.
			int databaseID = (sourcesPlist.count > 0) ? ([(NSNumber *)[sourcesPlist.allKeys valueForKeyPath:@"@max.self"] intValue] + 1) : 0;
			source.databaseID = databaseID;
			[self syncFilesForSource:source]; // Delete old entries with the same ID.
			sourcesPlist[@(databaseID)] = [@{
				@"baseURL" : source.baseURL.absoluteString,
				@"components" : ([source.components componentsJoinedByString:@" "] ?: @""),
				@"dist" : source.distribution,
				@"lastRefresh" : [[NSDate alloc] initWithTimeIntervalSince1970:0]
			} mutableCopy];
		}
		sources[[source sourcesListEntryWithComponents:NO]] = source;
		[self syncFilesForSource:source]; // Add the new source to the sources.plist file.
	}
	else {
		notificationName = DatabaseDidEncounterAnError;
		userInfo = @{@"error" : @"The new source cannot be added because it already exists."};
		returnValue = nil;
	}
	if (!repoID) {
		[NSNotificationCenter.defaultCenter
			postNotificationName:notificationName
			object:self
			userInfo:userInfo
		];
	}
	return returnValue;
}

- (Source *)addSourceWithBaseURL:(NSString *)baseURL distribution:(NSString *)dist components:(NSString *)components ID:(NSNumber *)_repoID {
	if (!sources) sources = [NSMutableDictionary new];
	__block Source *source = [[Source alloc] initWithBaseURL:baseURL distribution:dist components:components];
	if (source) {
		if (_repoID) {
			return [self addIncompleteSource:source ID:_repoID];
		}
		else {
			__block NSNumber *repoID = _repoID.copy;
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				source = [self addIncompleteSource:source ID:repoID] ?: nil;
			});
			return nil;
		}
	}
	else return nil;
}

- (void)waitForSourcesToRefresh {
	[_refreshQueue waitUntilAllOperationsAreFinished];
	[self reloadRemotePackages];
	[self syncFiles];
	NSLog(@"All of the sources refreshed.");
	_isRefreshing = NO;
	[NSNotificationCenter.defaultCenter
		postNotificationName:DatabaseDidFinishRefreshingSources
		object:self
		userInfo:nil
	];
}

+ (NSData *)requestDataFromURL:(NSURL *)url withRepositoryHeaders:(BOOL)includeRepositoryHeaders response:(NSHTTPURLResponse **)response timeoutInterval:(NSTimeInterval)timeoutInterval error:(NSError **)error {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeoutInterval];
	return [NSURLConnection sendSynchronousRequest:request returningResponse:(id *)response error:error];
}

+ (NSData *)requestDataFromURL:(NSURL *)url response:(NSHTTPURLResponse **)response timeoutInterval:(NSTimeInterval)timeoutInterval error:(NSError **)error {
	return [self requestDataFromURL:url withRepositoryHeaders:YES response:response timeoutInterval:timeoutInterval error:error];
}

+ (NSData *)requestDataFromURL:(NSURL *)url response:(NSHTTPURLResponse **)response error:(NSError **)error {
	return [self requestDataFromURL:url response:response timeoutInterval:30 error:error];
}

+ (NSData *)requestDataFromURL:(NSURL *)url error:(NSError **)error {
	return [self requestDataFromURL:url response:nil timeoutInterval:30 error:error];
}

- (void)refreshSource:(Source *)source {
	// Notify observers about the refresh operation
	source.isRefreshing = YES;
	[NSNotificationCenter.defaultCenter
		postNotificationName:SourceDidStartRefreshing
		object:self
		userInfo:@{ @"source" : source }
	];
	NSLog(@"Refreshing: %@", source);
	NSMutableDictionary *userInfo = @{
		@"source"    : source,
		@"reason"    : @"Operation completed successfully",
		@"errorCode" : NSNull.null // NSNull = success, NSNumber = failure
	}.mutableCopy;

	// Refresh
	NSURL *releaseFileURL = source.releaseFileURL;
	NSURL *packagesFileURL = source.packagesFileURL;
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [self.class requestDataFromURL:releaseFileURL response:&response error:nil];
	NSURL *lastURL = nil;
#define parseFailure() { \
	userInfo[@"reason"] = [NSString stringWithFormat:@"Client failed to parse the file from the following URL: %@", lastURL]; \
	userInfo[@"errorCode"] = @(-1); \
	NSLog(@"Error: %@", error); \
}
#define fetch(url, block...) \
lastURL = url; \
response = (id)(data = nil); \
data = [self.class requestDataFromURL:url response:&response error:nil]; \
if (!response || response.statusCode != 200) { \
	userInfo[@"reason"] = [NSString stringWithFormat:@"Server returned a status code other than 200 for the following URL: %@", url]; \
	userInfo[@"errorCode"] = @(response.statusCode); \
} else block
	fetch(releaseFileURL, {
		NSString *encodedFile = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		source.rawReleaseFile = encodedFile;
		if (source.rawReleaseFile) {
			fetch(packagesFileURL, {
				data = [BZipCompression decompressedDataWithData:data error:&error];
				if (!error && data) {
					NSString *fullPackages = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					NSArray<NSDictionary<NSString *, NSString *> *> *parsedFile = [DPKGParser parseFileContents:fullPackages error:&error];
					if (!error && parsedFile && fullPackages) {
						source.packages = [Package createPackagesUsingArray:parsedFile source:source];
						sourcesPlist[@(source.databaseID)][@"lastRefresh"] = NSDate.date;
					}
					else parseFailure();
				}
				else parseFailure();
			});
		}
		else parseFailure();
	});
	NSLog(@"[Refresh Result] %@", userInfo);
#undef fetch
#undef parseFailure
	// Notify observers about the completion of the operation
	source.isRefreshing = NO;
	[NSNotificationCenter.defaultCenter
		postNotificationName:SourceDidStopRefreshing
		object:self
		userInfo:userInfo.copy
	];
#if DEBUG
	if (![userInfo[@"errorCode"] isKindOfClass:[NSNull class]]) {
		[NSNotificationCenter.defaultCenter
			postNotificationName:DatabaseDidEncounterAnError
			object:self
			userInfo:@{ @"error" : userInfo[@"reason"] }
		];
	}
#endif
	userInfo = nil;
}

- (void)_reloadRemotePackages {
	NSMutableArray *remotePackages = [NSMutableArray new];
	for (Source *source in sources.allValues) {
		[remotePackages addObjectsFromArray:source.packages];
	}
	[remotePackages sortUsingSelector:@selector(compare:)];
	_sortedRemotePackages = remotePackages;
}

- (void)reloadRemotePackages {
	[self reloadRemotePackagesAsynchronously:NO];
}

- (void)reloadRemotePackagesAsynchronously:(BOOL)async {
	if (async) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			[self _reloadRemotePackages];
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidFinishReloadingRemotePackages
				object:self
				userInfo:nil
			];
		});
	}
	else {
		[self _reloadRemotePackages];
	}
}

// UNTESTED
- (Package *)packageWithIdentifier:(NSString *)identifier {
	return identifier ? ([_sortedRemotePackages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"package == %@", identifier]].lastObject ?: [_sortedLocalPackages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"package == %@", identifier]].lastObject) : nil;
}

- (void)startRefreshingSources {
	_isRefreshing = YES;
	_refreshQueue.suspended = YES;
	_refreshQueue = [NSOperationQueue new];
	_refreshQueue.underlyingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	for (Source *source in sources.allValues) {
		[_refreshQueue addOperation:[[NSInvocationOperation alloc]
			initWithTarget:self
			selector:@selector(refreshSource:)
			object:source
		]];
	}
	[NSThread
		detachNewThreadSelector:@selector(waitForSourcesToRefresh)
		toTarget:self
		withObject:nil
	];
}

@end