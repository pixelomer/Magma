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

static sqlite3 *magma_db;
static Database *sharedInstance;
static NSString *workingDirectory;

+ (instancetype)alloc {
	return sharedInstance ? nil : [super alloc];
}

+ (instancetype)sharedInstance {
	if (!sharedInstance) {
		if (!magma_db) {
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
	BOOL isDir;
	if (!([NSFileManager.defaultManager createDirectoryAtPath:[newLocation stringByAppendingPathComponent:@"lists"] withIntermediateDirectories:YES attributes:nil error:nil] && ([NSFileManager.defaultManager fileExistsAtPath:[newLocation stringByAppendingPathComponent:@"sources.plist"]] || [@{} writeToFile:[newLocation stringByAppendingPathComponent:@"sources.plist"] atomically:YES]))) {
		@throw [NSException
			exceptionWithName:NSInternalInconsistencyException
			reason:@"Failed to prepare the directory. Continuing execution will result in a crash so just crashing now."
			userInfo:nil
		];
	}
	workingDirectory = newLocation.copy;
}

+ (NSString *)workingDirectory {
	return workingDirectory;
}

+ (int)nextIdentifierForTable:(NSString *)tableName inSQLiteDatabase:(sqlite3 *)db {
	sqlite3_stmt *statement;
	int nextID = 0;
	if (sqlite3_prepare_v2(db, [NSString stringWithFormat:@"SELECT MAX(`id`) FROM `%@`", tableName].UTF8String, -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			nextID = sqlite3_column_int(statement, 0) + 1;
		}
		sqlite3_finalize(statement);
	}
	else NSLog(@"%s", sqlite3_errmsg(magma_db));
	return nextID;
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

- (void)startLoadingDataIfNeeded {
	if (!_isLoaded) {
		if (!magma_db) {
			@throw [NSException
				exceptionWithName:NSInternalInconsistencyException
				reason:@"The sqlite3 database has to be opened before calling this method. Call +[Database setWorkingDirectory:] in order to do so."
				userInfo:nil
			];
		}
		// Load data from the filesystem
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			BOOL success = YES;
			sqlite3_stmt *statement;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpointer-sign"

			// Load repositories from database
			if (success = (sqlite3_prepare_v2(magma_db, "SELECT * FROM `repositories`", -1, &statement, NULL) == SQLITE_OK)) {
				NSMutableArray *rows = [NSMutableArray new];
				while (sqlite3_step(statement) == SQLITE_ROW) {
					int            repo_id = sqlite3_column_int(statement, 0);  // Unique
					const char   *base_url = sqlite3_column_text(statement, 1); // Composite Primary
					const char       *dist = sqlite3_column_text(statement, 2); // Composite Primary
					const char *components = sqlite3_column_text(statement, 3); // Composite Primary (can be an empty string)
					const char    *Release = sqlite3_column_text(statement, 4); // Full Release file, can be null
					NSTimeInterval lastRefreshInterval = sqlite3_column_double(statement, 5);
					NSLog(@"%f", lastRefreshInterval);
					BOOL       isBasicRepo = (!components || !*components);
					//                 0           1            2        3                        4                          5               6
					[rows addObject:@[@(repo_id), @(base_url), @(dist), @(components), Release ? @(Release) : NSNull.null, @(isBasicRepo), @(lastRefreshInterval)]];
				}
				sqlite3_finalize(statement);
				for (NSArray *row in rows) {
					Source *source;
					if ([(NSNumber *)row[5] boolValue]) {
						source = [self addSourceWithURL:row[1] ID:row[0]];
					}
					else {
						source = [self addSourceWithBaseURL:row[1] distribution:row[2] components:row[3] ID:row[0]];
					}
					if (source) {
						if ([row[4] isKindOfClass:[NSString class]]) {
							source.rawReleaseFile = row[4];
						}
						NSTimeInterval lastRefresh = [(NSNumber *)row[6] doubleValue];
						source.lastRefresh = [NSDate dateWithTimeIntervalSince1970:lastRefresh];
						NSMutableArray *packages = [NSMutableArray new];
						if (sqlite3_prepare_v2(magma_db, "SELECT `ignore_updates`, `control`, `first_discovery` FROM `packages` WHERE `repo_id`=?", -1, &statement, NULL) == SQLITE_OK) {
							sqlite3_bind_int(statement, 1, source.databaseID);
							while (sqlite3_step(statement) == SQLITE_ROW) {
								BOOL ignoresUpdates = sqlite3_column_int(statement, 0);
								NSString *control = @((const char *)sqlite3_column_text(statement, 1));
								NSDate *firstDiscovery = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(statement, 2)];
								NSDictionary *dict = [DPKGParser parsePackageEntry:control error:nil];
								NSLog(@"dict: %@", dict);
								if (dict) {
									Package *package = [[Package alloc] initWithDictionary:dict source:source];
									package.firstDiscovery = firstDiscovery;
									package.ignoresUpdates = ignoresUpdates;
									if (package) [packages addObject:package];
								}
							}
							sqlite3_finalize(statement);
						}
						source.packages = packages.copy;
					}
				}
			}

			// Load local packages from /var/lib/dpkg
			[self reloadLocalPackages];
			
			// Put packages from all of the sources into one sorted array
			[self reloadRemotePackages];

#pragma GCC diagnostic pop
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
		sqlite3_stmt *statement;
		BOOL isSourceKnown = NO;
		NSArray<NSString *> *keys = sources.allKeys.copy;
		for (NSString *knownSourceIdentifier in keys) {
			Source *knownSource = sources[knownSourceIdentifier];
			if (knownSource == source) {
				[sources removeObjectForKey:knownSourceIdentifier];
				[self reloadRemotePackages];
				isSourceKnown = YES;
			}
		}
		BOOL success = YES;
		if (isSourceKnown && (success = (sqlite3_prepare_v2(magma_db, "DELETE FROM `repositories` WHERE `id`=?", -1, &statement, NULL) == SQLITE_OK))) {
			sqlite3_bind_int(statement, 1, source.databaseID);
			success = (sqlite3_step(statement) == SQLITE_DONE);
			sqlite3_finalize(statement);
		}
		if (success) {
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidRemoveSource
				object:self
				userInfo:@{ @"source" : source }
			];
		}
		else {
			@throw [NSException
				exceptionWithName:NSInternalInconsistencyException
				reason:[NSString stringWithFormat:@"Failed to prepare the SQLite query to remove the specified source. This can cause the application to behave unexpectedly.\nSQLite Error: %s", sqlite3_errmsg(magma_db)]
				userInfo:nil
			];
		}
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
			BOOL success = YES;
			int databaseID = [self.class nextIdentifierForTable:@"repositories" inSQLiteDatabase:magma_db];
			source.databaseID = databaseID;
			sqlite3_stmt *statement;
			if (success = (sqlite3_prepare_v2(magma_db, "INSERT OR REPLACE INTO `repositories` (`id`, `base_url`, `dist`, `components`) VALUES (?, ?, ?, ?)", -1, &statement, NULL) == SQLITE_OK)) {
				sqlite3_bind_int(statement, 1, databaseID);
				sqlite3_bind_text(statement, 2, source.baseURL.absoluteString.UTF8String);
				sqlite3_bind_text(statement, 3, source.distribution.UTF8String);
				sqlite3_bind_text(statement, 4, [source.components componentsJoinedByString:@" "].UTF8String ?: "");
				success = (sqlite3_step(statement) == SQLITE_DONE);
				sqlite3_finalize(statement);
			}
			if (!success) {
				notificationName = DatabaseDidEncounterAnError;
				userInfo = @{@"error" : [NSString stringWithFormat:@"An SQLite error occurred while adding the source: %s", sqlite3_errmsg(magma_db)]};
				returnValue = nil;
			}
			else if (sqlite3_prepare_v2(magma_db, "DELETE FROM `packages` WHERE `repo_id`=?", -1, &statement, NULL) == SQLITE_OK) {
				sqlite3_bind_int(statement, 1, databaseID);
				sqlite3_step(statement);
				sqlite3_finalize(statement);
			}
		}
		sources[[source sourcesListEntryWithComponents:NO]] = source;
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
	NSDate *lastRefresh = NSDate.date;
	NSTimeInterval lastRefreshInterval = lastRefresh.timeIntervalSince1970;
	[self reloadRemotePackages];
	for (Source *source in sources.allValues) {
		sqlite3_stmt *statement;
		if (sqlite3_prepare_v2(magma_db, "UPDATE `repositories` SET `Release`=?, `last_refresh`=? WHERE `id`=?", -1, &statement, NULL) == SQLITE_OK) {
			if (source.rawReleaseFile) {
				sqlite3_bind_text(statement, 1, source.rawReleaseFile.UTF8String);
				sqlite3_bind_double(statement, 2, lastRefreshInterval);
				source.lastRefresh = lastRefresh;
			}
			else {
				sqlite3_bind_null(statement, 1);
				sqlite3_bind_null(statement, 2);
				source.lastRefresh = nil;
			}
			sqlite3_bind_int(statement, 3, source.databaseID);
			BOOL success = (sqlite3_step(statement) == SQLITE_DONE);
			sqlite3_finalize(statement);
			if (success) {
				NSMutableDictionary *oldPackagesDictionary = [NSMutableDictionary new];
				if (sqlite3_prepare_v2(magma_db, "SELECT `ignore_updates`, `package`, `version`, `first_discovery` FROM `packages` WHERE `repo_id`=?", -1, &statement, NULL) == SQLITE_OK) {
					sqlite3_bind_int(statement, 1, source.databaseID);
					while (sqlite3_step(statement) == SQLITE_ROW) {
						NSNumber *ignoreUpdates = @(sqlite3_column_int(statement, 0));
						NSString *packageID = @((const char *)sqlite3_column_text(statement, 1));
						NSString *version = @((const char *)sqlite3_column_text(statement, 2));
						NSDate *firstDiscovery = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(statement, 3)];
						NSString *key = [NSString stringWithFormat:@"%@ %@", packageID, version];
						oldPackagesDictionary[key] = @[ignoreUpdates, firstDiscovery];
					}
					sqlite3_finalize(statement);
					if (sqlite3_prepare_v2(magma_db, "DELETE FROM `packages` WHERE `repo_id`=?", -1, &statement, NULL) == SQLITE_OK) {
						sqlite3_bind_int(statement, 1, source.databaseID);
						success = (sqlite3_step(statement) == SQLITE_DONE);
						sqlite3_finalize(statement);
						if (success) {
							int nextID = [self.class nextIdentifierForTable:@"packages" inSQLiteDatabase:magma_db];
							for (Package *newPackage in source.packages) {
								NSString *key = [NSString stringWithFormat:@"%@ %@", newPackage.package, newPackage.version];
								NSArray *oldInfo = oldPackagesDictionary[key];
								if (oldInfo) {
									newPackage.ignoresUpdates = [(NSNumber *)oldInfo[0] boolValue];
									newPackage.firstDiscovery = oldInfo[1];
								}
								else {
									newPackage.ignoresUpdates = NO;
									newPackage.firstDiscovery = lastRefresh;
								}
								if (sqlite3_prepare_v2(magma_db, "INSERT INTO `packages` VALUES (?, ?, ?, ?, ?, ?, ?)", -1, &statement, NULL) == SQLITE_OK) {
									sqlite3_bind_int(statement, 1, nextID++);
									sqlite3_bind_int(statement, 2, source.databaseID);
									sqlite3_bind_int(statement, 3, !!newPackage.ignoresUpdates);
									sqlite3_bind_text(statement, 4, newPackage.package.UTF8String);
									sqlite3_bind_text(statement, 5, newPackage.version.UTF8String);
									sqlite3_bind_text(statement, 6, newPackage.rawPackagesEntry.UTF8String);
									sqlite3_bind_double(statement, 7, newPackage.firstDiscovery.timeIntervalSince1970);
									sqlite3_step(statement);
									sqlite3_finalize(statement);
								}
							}
						}
					}
				}
			}
		}
	}
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

- (void)_reloadLocalPackages {
	NSArray *newlySortedLocalPackageDicts = [DPKGParser parseFileAtPath:@"/var/lib/dpkg/status" error:nil];
	if (!newlySortedLocalPackageDicts) _sortedLocalPackages = @[];
	else {
		NSMutableArray *newlySortedLocalPackages = [Package createPackagesUsingArray:newlySortedLocalPackageDicts source:nil].mutableCopy;
		[newlySortedLocalPackages sortUsingSelector:@selector(compare:)];
		_sortedLocalPackages = newlySortedLocalPackages;
	}
}

- (void)_reloadRemotePackages {
	NSMutableArray *remotePackages = [NSMutableArray new];
	for (Source *source in sources.allValues) {
		[remotePackages addObjectsFromArray:source.packages];
	}
	[remotePackages sortUsingSelector:@selector(compare:)];
	_sortedRemotePackages = remotePackages;
}

- (void)reloadLocalPackages {
	[self reloadLocalPackagesAsynchronously:NO];
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

- (void)reloadLocalPackagesAsynchronously:(BOOL)async {
	if (async) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			[self _reloadLocalPackages];
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidFinishReloadingLocalPackages
				object:self
				userInfo:nil
			];
		});
	}
	else {
		[self _reloadLocalPackages];
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