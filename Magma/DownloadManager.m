//
//  DownloadManager.m
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "DownloadManager.h"
#import "AppDelegate.h"
#import <Compression/Compression.h>
#import "Package.h"
#import <objc/runtime.h>

@implementation DownloadManager

static DownloadManager *sharedInstance;
static NSString *workingDirectory;

+ (instancetype)sharedInstance {
	if (!sharedInstance) {
		workingDirectory = AppDelegate.workingDirectory;
		if (!([NSFileManager.defaultManager createDirectoryAtPath:[workingDirectory stringByAppendingPathComponent:@"downloads"] withIntermediateDirectories:YES attributes:nil error:nil] && (([NSFileManager.defaultManager removeItemAtPath:[workingDirectory stringByAppendingPathComponent:@"downloads.tmp"] error:nil] && false) || [NSFileManager.defaultManager createDirectoryAtPath:[workingDirectory stringByAppendingPathComponent:@"downloads.tmp"] withIntermediateDirectories:YES attributes:nil error:nil]))) {
			@throw [NSException
				exceptionWithName:NSInternalInconsistencyException
				reason:@"Failed to prepare the directory. Continuing execution will result in a crash so just crashing now."
				userInfo:nil
			];
		}
		sharedInstance = [self new];
	}
	return sharedInstance;
}

+ (instancetype)alloc {
	return sharedInstance ? nil : [super alloc];
}

- (instancetype)init {
	if (self = [super init]) {
		NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
		if (@available(iOS 11.0, *)) {
			config.waitsForConnectivity = YES;
		}
		config.timeoutIntervalForRequest = 10;

		URLSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
		tasks = [NSMutableDictionary new];
		allPackages = [NSMutableArray new];
	}
	return self;
}

- (NSString *)downloadsPath {
	return [workingDirectory stringByAppendingPathComponent:@"downloads"];
}

- (NSString *)temporaryDownloadsPath {
	return [workingDirectory stringByAppendingPathComponent:@"downloads.tmp"];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	int64_t totalReceivedData = downloadTask.countOfBytesReceived;
	int64_t totalData = downloadTask.countOfBytesExpectedToReceive;
	NSUInteger taskIdentifier = downloadTask.taskIdentifier;
	NSNumber *key = @(taskIdentifier);
	NSPointerArray *taskDelegates = tasks[key][0];
	key = nil;
	[taskDelegates compact];
	for (NSUInteger i = 0; i < taskDelegates.count; i++) {
		__weak id<DownloadManagerDelegate> delegate = [taskDelegates pointerAtIndex:i];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			[delegate downloadWithIdentifier:taskIdentifier didReceiveBytes:totalReceivedData totalBytes:totalData];
		});
	}
}

- (int64_t)totalBytesForIdentifier:(NSUInteger)identifier {
	return [(NSURLSessionDownloadTask *)tasks[@(identifier)][2] countOfBytesExpectedToReceive];
}

- (int64_t)receivedBytesForIdentifier:(NSUInteger)identifier {
	return [(NSURLSessionDownloadTask *)tasks[@(identifier)][2] countOfBytesReceived];
}

- (NSInteger)ongoingDownloadCount {
	return tasks.count;
}

- (NSArray<NSNumber *> *)allTaskIdentifiers {
	return tasks.allKeys;
}

- (BOOL)isPackageBeingDownloaded:(Package *)remotePackage {
	return [allPackages containsObject:[NSString stringWithFormat:@"%@ %@", remotePackage.package, remotePackage.version]];
}

- (NSString *)packageNameForTaskWithIdentifier:(NSUInteger)taskID {
	return [(NSString *)tasks[@(taskID)][1] componentsSeparatedByString:@" "].firstObject;
}

- (void)finalizeDownloadWithIdentifier:(NSUInteger)identifier error:(NSString *)error {
	NSNumber *key = @(identifier);
	if (!tasks[key]) return;
	NSPointerArray *taskDelegates = tasks[key][0];
	[taskDelegates compact];
	for (NSUInteger i = 0; i < taskDelegates.count; i++) {
		__weak id<DownloadManagerDelegate> delegate = [taskDelegates pointerAtIndex:i];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			[delegate downloadWithIdentifier:identifier didCompleteWithError:error];
		});
	}
	taskDelegates = nil;
	//if (error) (retryKeys ?: (retryKeys = [NSMutableDictionary new]))[key] = @[ tasks[key][1], tasks[key][3] ];
	NSString *packageName = [(NSString *)tasks[key][1] componentsSeparatedByString:@" "].firstObject;
	[tasks removeObjectForKey:key];
	[NSNotificationCenter.defaultCenter
		postNotificationName:DownloadDidCompleteNotification
		object:self
		userInfo:@{ @"packageName" : packageName, @"taskID" : key, @"error" : (error ?: NSNull.null) }
	];
}

- (void)finalizeDownloadWithIdentifier:(NSUInteger)identifier packageName:(NSString *)packageName downloadedFilePath:(NSString *)downloadedFile {
	BOOL isDir;
	if ([NSFileManager.defaultManager fileExistsAtPath:downloadedFile isDirectory:&isDir] && !isDir) {
		NSString *archiveOut = [downloadedFile stringByAppendingString:@".tmp"];
		[NSFileManager.defaultManager removeItemAtPath:archiveOut error:nil];
		if ([NSData unarchiveFileAtPath:downloadedFile toDirectoryAtPath:archiveOut]) {
			NSString *finalOutput = [downloadedFile stringByAppendingString:@".out"];
			[NSFileManager.defaultManager removeItemAtPath:finalOutput error:nil];
			NSDictionary *possibleExtensions = @{
				@".xz" : @"extractXZFileAtPath:toFileAtPath:",
				@".lzma" : @"extractLZMAFileAtPath:toFileAtPath:",
				@".gz" : @"gunzipFile:toFile:"
			};
			NSArray *files = @[
				[archiveOut stringByAppendingPathComponent:@"control.tar"],
				[archiveOut stringByAppendingPathComponent:@"data.tar"]
			];
			for (NSString *file in files) {
				if ([NSFileManager.defaultManager fileExistsAtPath:file]) continue;
				for (NSString *possibleExtension in possibleExtensions) {
					NSString *fileWithExtension = [file stringByAppendingString:possibleExtension];
					if ([NSFileManager.defaultManager fileExistsAtPath:fileWithExtension]) {
						NSString *selectorString = possibleExtensions[possibleExtension];
						SEL selector = NSSelectorFromString(selectorString);
						BOOL (*extract)(Class, SEL, id, id);
						extract = (BOOL(*)(Class, SEL, id, id))(method_getImplementation(class_getClassMethod(NSData.class, selector)));
						if (!extract(NSData.class, selector, fileWithExtension, file)) {
							[NSFileManager.defaultManager removeItemAtPath:file error:nil];
						}
						else break;
					}
				}
			}
			NSUInteger counter = 0;
			for (NSString *file in files) {
				counter += !![NSFileManager.defaultManager fileExistsAtPath:file];
			}
			if (counter == files.count) {
				NSString *pathToMove = [self.downloadsPath stringByAppendingPathComponent:packageName];
				if ([NSFileManager.defaultManager createFilesAndDirectoriesAtPath:finalOutput withTarPath:files[1] error:nil progress:nil] && [NSFileManager.defaultManager createFilesAndDirectoriesAtPath:[finalOutput stringByAppendingPathComponent:@"DEBIAN"] withTarPath:files[0] error:nil progress:nil] && ([NSFileManager.defaultManager removeItemAtPath:pathToMove error:nil] || true) && [NSFileManager.defaultManager moveItemAtPath:finalOutput toPath:pathToMove error:nil]) {
					[self finalizeDownloadWithIdentifier:identifier error:nil];
					return;
				}
			}
		}
	}
	[self finalizeDownloadWithIdentifier:identifier error:@"Failed to extract the downloaded archive."];
}

- (void)URLSession:(NSURLSession *)urlSession downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
	NSUInteger downloadTaskIdentifier = downloadTask.taskIdentifier;
	__block NSString *packageName = [(NSString *)tasks[@(downloadTaskIdentifier)][1] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	__block NSString *downloadedFile = [self.temporaryDownloadsPath stringByAppendingPathComponent:[packageName stringByAppendingString:@".deb"]];
	[NSFileManager.defaultManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:downloadedFile] error:nil];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		[self finalizeDownloadWithIdentifier:downloadTaskIdentifier packageName:packageName downloadedFilePath:downloadedFile];
		packageName = nil;
		downloadedFile = nil;
	});
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	if (error) {
		[self finalizeDownloadWithIdentifier:task.taskIdentifier error:error.localizedDescription];
	}
}

- (NSString *)localPathForRemotePackage:(Package *)remotePackage {
	return [[self.downloadsPath stringByAppendingPathComponent:remotePackage.package] stringByAppendingString:remotePackage.version];
}

/*
- (BOOL)retryDownloadWithIdentifier:(NSUInteger)identifier {
	NSNumber *key = @(identifier);
	BOOL result = [self startDownloadingWithKey:retryKeys[key][0] URL:retryKeys[key][1] remotePackage:nil];
	[retryKeys removeObjectForKey:key];
	return result;
}
*/

- (BOOL)startDownloadingWithKey:(NSString *)key URL:(NSURL *)url remotePackage:(Package *)remotePackage {
	if ([allPackages containsObject:key]) return NO;
	NSURLSessionDownloadTask *downloadTask = [URLSession downloadTaskWithURL:url];
	tasks[@(downloadTask.taskIdentifier)] = @[
		[NSPointerArray weakObjectsPointerArray],
		key,
		downloadTask,
		url
	];
	[NSNotificationCenter.defaultCenter
		postNotificationName:DownloadDidStartNotification
		object:self
		userInfo:@{ @"taskID" : @(downloadTask.taskIdentifier), @"remotePackage" : remotePackage ?: NSNull.null }
	];
	[downloadTask resume];
	return YES;
}

- (BOOL)startDownloadingPackage:(Package *)remotePackage {
	NSString *key = [NSString stringWithFormat:@"%@ %@", remotePackage.package, remotePackage.version];
	NSURL *url = remotePackage.debURL;
	return [self startDownloadingWithKey:key URL:url remotePackage:remotePackage];
}

- (void)addDelegate:(id<DownloadManagerDelegate>)newDelegate forDownloadWithIdentifier:(NSUInteger)identifier {
	[tasks[@(identifier)][0] addPointer:(__bridge void *)newDelegate];
}

- (void)removeDelegate:(id<DownloadManagerDelegate>)oldDelegate forDownloadWithIdentifier:(NSUInteger)identifier {
	NSPointerArray *delegateArray = tasks[@(identifier)][0];
	for (NSUInteger i = 0; i < delegateArray.count; i++) {
		id pointer = (__bridge id)[delegateArray pointerAtIndex:i];
		if (pointer == oldDelegate) {
			[delegateArray removePointerAtIndex:i];
			i--;
		}
	}
}

@end
