#import "Database.h"
#import "Source.h"
#import "DPKGParser.h"
#import "Package.h"
#import <objc/runtime.h>
#import "AppDelegate.h"

@interface Source(Private)
- (void)setIsRefreshing:(BOOL)isRefreshing;
- (void)setLastRefresh:(NSDate *)lastRefresh;
@end

@interface Package(Private)
- (void)setFirstDiscovery:(NSDate *)firstDiscovery;
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
		workingDirectory = AppDelegate.workingDirectory;
		if (!([NSFileManager.defaultManager createDirectoryAtPath:[workingDirectory stringByAppendingPathComponent:@"lists"] withIntermediateDirectories:YES attributes:nil error:nil] && ([NSFileManager.defaultManager fileExistsAtPath:[workingDirectory stringByAppendingPathComponent:@"sources.plist"]] || [@{} writeToFile:[workingDirectory stringByAppendingPathComponent:@"sources.plist"] atomically:YES]))) {
			@throw [NSException
				exceptionWithName:NSInternalInconsistencyException
				reason:@"Failed to prepare the directory. Continuing execution will result in a crash so just crashing now."
				userInfo:nil
			];
		}
		paths = @[
			[workingDirectory stringByAppendingPathComponent:@"sources.plist"],
			[workingDirectory stringByAppendingPathComponent:@"lists"]
		];
		sharedInstance = [self new];
	}
	return sharedInstance;
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
		_sortedRemotePackages = @[];
	}
	return self;
}

- (void)syncSourcesPlist {
	NSMutableDictionary *serializableSourcesPlist = [NSMutableDictionary new];
	for (NSNumber *NSID in sourcesPlist) {
		NSString *ID = [NSID stringValue];
		serializableSourcesPlist[ID] = sourcesPlist[NSID];
	}
	[serializableSourcesPlist writeToFile:self.class.sourcesPlistPath atomically:YES];
}

+ (NSString *)releaseFilePathForSource:(Source *)source {
	return [self.listsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i_Release.plist", source.databaseID]];
}

+ (NSString *)packagesFilePathForSource:(Source *)source {
	return [self.listsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i_Packages", source.databaseID]];
}

+ (NSDictionary *)releaseFileForSourceFromDisk:(Source *)source {
	return [NSDictionary dictionaryWithContentsOfFile:[self releaseFilePathForSource:source]];
}

+ (NSString *)packagesFileForSourceFromDisk:(Source *)source {
	return [NSString stringWithContentsOfFile:[self packagesFilePathForSource:source] encoding:NSUTF8StringEncoding error:nil];
}

- (void)_loadDataForSourceWithArray:(NSArray *)dataToProcess {
	Source *source = dataToProcess[1];
	NSDictionary<NSString *, id> *sourceDict = dataToProcess[0];
	source.parsedReleaseFile = [self.class releaseFileForSourceFromDisk:source];
	source.lastRefresh = sourceDict[@"lastRefresh"];
	[source reloadPackagesFile];
}

- (void)_loadData {
	// Load repositories
	if (self->_isLoading) return;
	self->_isLoading = YES;
	self->sourcesPlist = [NSMutableDictionary new];
	NSDictionary<NSString *, NSDictionary *> *storedFile = [[NSDictionary alloc] initWithContentsOfFile:self.class.sourcesPlistPath];
	for (NSString *ID in storedFile) {
		NSNumber *NSID = @([ID intValue]);
		self->sourcesPlist[NSID] = storedFile[ID].mutableCopy;
	}
	NSArray<NSNumber *> *keys = self->sourcesPlist.allKeys.copy;
	NSOperationQueue *queue = [NSOperationQueue new];
	for (NSNumber *_sourceID in keys) {
		Source *source;
		NSDictionary<NSString *, id> *sourceDict = self->sourcesPlist[_sourceID];
		if ([(NSString *)sourceDict[@"components"] length] <= 0) {
			source = [self addSourceWithURL:sourceDict[@"baseURL"] architecture:sourceDict[@"arch"] ID:_sourceID];
		}
		else {
			source = [self addSourceWithBaseURL:sourceDict[@"baseURL"] architecture:sourceDict[@"arch"] distribution:sourceDict[@"dist"] components:sourceDict[@"components"] ID:_sourceID];
		}
		if (source) {
			[queue addOperation:[[NSInvocationOperation alloc]
				initWithTarget:self
				selector:@selector(_loadDataForSourceWithArray:)
				object:@[sourceDict, source]
			]];
		}
	}
	
	[queue waitUntilAllOperationsAreFinished];
	
	// Put packages from all of the sources into one sorted array
	[self reloadRemotePackages];

	self->_isLoaded = YES;
	[NSNotificationCenter.defaultCenter
		postNotificationName:DatabaseDidLoad
		object:self
		userInfo:nil
	];
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
		[NSThread detachNewThreadSelector:@selector(_loadData) toTarget:self withObject:nil];
	}
}

- (NSArray *)sources {
	return (id)[sources allValues];
}

- (void)removeSource:(Source *)source {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (self->_isRefreshing) {
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidEncounterAnError
				object:self
				userInfo:@{ @"error" : @"It is not possible to remove a source while refreshing." }
			];
		}
		BOOL isSourceKnown = NO;
		NSArray<NSString *> *keys = self->sources.allKeys.copy;
		for (NSString *knownSourceIdentifier in keys) {
			Source *knownSource = self->sources[knownSourceIdentifier];
			if (knownSource == source) {
				[self->sources removeObjectForKey:knownSourceIdentifier];
				isSourceKnown = YES;
			}
		}
		if (isSourceKnown) {
			[source deleteFiles];
			[self->sourcesPlist removeObjectForKey:@(source.databaseID)];
			[self syncSourcesPlist];
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidRemoveSource
				object:self
				userInfo:@{ @"source" : source }
			];
			[self reloadRemotePackages];
		}
	});
}

- (void)addSourceWithURL:(NSString *)baseURL architecture:(NSString *)arch {
	[self addSourceWithBaseURL:baseURL architecture:arch distribution:@"./" components:nil];
}

- (Source *)addSourceWithURL:(NSString *)baseURL architecture:(NSString *)arch ID:(NSNumber *)repoID {
	return [self addSourceWithBaseURL:baseURL architecture:arch distribution:@"./" components:nil ID:repoID];
}

- (void)addSourceWithBaseURL:(NSString *)baseURL architecture:(NSString *)arch distribution:(NSString *)dist components:(NSString *)components {
	if (_isRefreshing) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidEncounterAnError
				object:self
				userInfo:@{ @"error" : @"It is not possible to add a source while refreshing." }
			];
		});
	}
	[self addSourceWithBaseURL:baseURL architecture:arch distribution:dist components:components ID:nil];
}

- (void)addPPA:(NSString *)ppa distribution:(NSString *)dist architecture:(NSString *)architecture {
	NSString *finalPPA = [ppa.lowercaseString hasPrefix:@"ppa:"] ? [ppa substringFromIndex:4] : ppa;
	[self addSourceWithBaseURL:[[[NSURL URLWithString:@"http://ppa.launchpad.net/"] URLByAppendingPathComponent:[finalPPA stringByAppendingPathComponent:@"ubuntu"]] absoluteString] architecture:architecture distribution:dist components:@"main"];
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
			[source deleteFiles]; // Delete old entries with the same ID.
			sourcesPlist[@(databaseID)] = [@{
				@"baseURL" : source.baseURL.absoluteString,
				@"components" : ([source.components componentsJoinedByString:@" "] ?: @""),
				@"dist" : source.distribution,
				@"lastRefresh" : [[NSDate alloc] initWithTimeIntervalSince1970:0],
				@"arch" : source.architecture
			} mutableCopy];
		}
		sources[[source sourcesListEntryWithComponents:NO]] = source;
		if (self->_isLoaded) [self syncSourcesPlist]; // Add the new source to the sources.plist file.
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

- (Source *)addSourceWithBaseURL:(NSString *)baseURL architecture:(NSString *)arch distribution:(NSString *)dist components:(NSString *)components ID:(NSNumber *)_repoID {
	if (!sources) sources = [NSMutableDictionary new];
	__block Source *source = [[Source alloc] initWithBaseURL:baseURL architecture:arch distribution:dist components:components];
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
	_refreshQueue.suspended = YES;
	_refreshQueue = nil;
	NSLog(@"All of the sources refreshed.");
	_isRefreshing = NO;
	[NSNotificationCenter.defaultCenter
		postNotificationName:DatabaseDidFinishRefreshingSources
		object:self
		userInfo:nil
	];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
	NSString *filePath = objc_getAssociatedObject(downloadTask, @selector(fetchURL:outputUserInfo:outputFile:));
	[NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
	[NSFileManager.defaultManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];
	objc_setAssociatedObject(downloadTask, @selector(fetchURL:outputUserInfo:outputFile:), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	objc_setAssociatedObject(task, @selector(fetchURL:outputUserInfo:outputFile:), error, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fetchURL:(NSURL *)url outputUserInfo:(NSMutableDictionary *)userInfo outputFile:(NSString *)filePath {
	NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:self delegateQueue:nil];
	NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
	objc_setAssociatedObject(task, _cmd, filePath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[task resume];
	NSError *error;
	while ((id)(error = objc_getAssociatedObject(task, _cmd)) == filePath) {
		[NSThread sleepForTimeInterval:0.2];
	}
	NSHTTPURLResponse *response = (id)task.response;
	if (error) {
		userInfo[@"reason"] = error.description;
		userInfo[@"errorCode"] = @(error.code);
		error = nil;
		objc_setAssociatedObject(task, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		return NO;
	}
	else if (!response || response.statusCode != 200) {
        userInfo[@"reason"] = [NSString stringWithFormat:@"Server returned a status code other than 200 for the following URL: %@", url];
        userInfo[@"errorCode"] = @(response.statusCode);
        return NO;
    } else {
        userInfo[@"reason"] = @"Operation completed successfully";
        userInfo[@"errorCode"] = NSNull.null;
        return YES;
    }
}

- (void)refreshSource:(Source *)source {
	// Notify observers about the refresh operation
	source.isRefreshing = YES;
	[source unloadPackagesFile];
	[NSNotificationCenter.defaultCenter
		postNotificationName:SourceDidStartRefreshing
		object:self
		userInfo:@{ @"source" : source }
	];
	NSLog(@"Refreshing: %@", source);
	NSMutableDictionary *userInfo = @{
		@"source"    : source
	}.mutableCopy;

	// Refresh
    NSData *data;
	NSURL *releaseFileURL = source.releaseFileURL;
	NSError *error = nil;
#define parseFailure() { \
	NSLog(@"Error: %@", error); \
}
	NSString *releaseFilePath = [[self.class releaseFilePathForSource:source] stringByAppendingString:@".raw"];
	if ([self fetchURL:releaseFileURL outputUserInfo:userInfo outputFile:releaseFilePath]) {
		NSString *encodedFile = [[NSString alloc] initWithContentsOfFile:releaseFilePath encoding:NSUTF8StringEncoding error:nil];
		source.rawReleaseFile = encodedFile;
		if (source.rawReleaseFile) {
			NSDictionary *packagesFileURLsForEveryComponent = source.possiblePackagesFileURLs;
			NSString *finalPackagesPath = [self.class packagesFilePathForSource:source];
			NSString *temporaryPackagesPath = [finalPackagesPath stringByAppendingString:@"_tmp"];
			FILE *newFile = fopen(temporaryPackagesPath.UTF8String, "w");
			NSString *packagesFilePath = [finalPackagesPath stringByAppendingString:@"_raw"];
			NSString *decompressedFilePath = [finalPackagesPath stringByAppendingString:@"_decompressed"];
			for (NSDictionary *possiblePackagesFileURLs in packagesFileURLsForEveryComponent.allValues) {
				for (NSString *algorithm in possiblePackagesFileURLs) {
					NSURL *packagesFileURL = possiblePackagesFileURLs[algorithm];
                    if ([self fetchURL:packagesFileURL outputUserInfo:userInfo outputFile:packagesFilePath] && [Source extractPackagesFile:packagesFilePath toFile:decompressedFilePath usingAlgorithm:algorithm]) {
                    	FILE *decompressedFileHandle = fopen(decompressedFilePath.UTF8String, "r");
						size_t bufferSize = 0x1000;
						size_t readBytes = 0;
						unsigned char *buffer = malloc(bufferSize);
                    	do {
							readBytes = fread(buffer, 1, bufferSize, decompressedFileHandle);
							if (!ferror(decompressedFileHandle)) {
								fwrite(buffer, readBytes, 1, newFile);
							}
							else {
								break;
							}
						} while (!feof(decompressedFileHandle));
						free(buffer);
						break;
					}
				}
			}
			NSError *error;
			fclose(newFile);
			[NSFileManager.defaultManager
				removeItemAtPath:finalPackagesPath
				error:&error
			];
			[NSFileManager.defaultManager
				moveItemAtPath:temporaryPackagesPath
				toPath:finalPackagesPath
				error:&error
			];
			[NSFileManager.defaultManager
				removeItemAtPath:temporaryPackagesPath
				error:nil
			];
		}
		else parseFailure();
    }
    [source reloadPackagesFile];
	sourcesPlist[@(source.databaseID)][@"lastRefresh"] = NSDate.date;
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
	data     = nil;
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
	return identifier ? [_sortedRemotePackages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"package == %@", identifier]].lastObject : nil;
}

- (void)startRefreshingSources {
	_isRefreshing = YES;
	[NSNotificationCenter.defaultCenter
		postNotificationName:DatabaseDidStartRefreshingSources
		object:self
		userInfo:nil
	];
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
