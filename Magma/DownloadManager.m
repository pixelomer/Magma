//
//  DownloadManager.m
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "DownloadManager.h"
#import "AppDelegate.h"
#import "Package.h"

@implementation DownloadManager

static DownloadManager *sharedInstance;
static NSString *workingDirectory;

+ (instancetype)sharedInstance {
	if (!sharedInstance) {
		workingDirectory = AppDelegate.workingDirectory;
		if (!([NSFileManager.defaultManager createDirectoryAtPath:[workingDirectory stringByAppendingPathComponent:@"downloads"] withIntermediateDirectories:YES attributes:nil error:nil])) {
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

- (void)finalizeDownloadWithIdentifier:(NSUInteger)identifier result:(BOOL)result {
	NSNumber *key = @(identifier);
	NSPointerArray *taskDelegates = tasks[key][0];
	[taskDelegates compact];
	for (NSUInteger i = 0; i < taskDelegates.count; i++) {
		__weak id<DownloadManagerDelegate> delegate = [taskDelegates pointerAtIndex:i];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			[delegate downloadWithIdentifier:identifier didCompleteWithSuccess:result];
		});
	}
	taskDelegates = nil;
	[tasks removeObjectForKey:key];
	[NSNotificationCenter.defaultCenter
		postNotificationName:DownloadDidCompleteNotification
		object:self
		userInfo:@{ @"taskID" : key, @"result" : @(result) }
	];
}

- (void)URLSession:(NSURLSession *)urlSession downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
	// Parse, extract, do other stuff, ???, profit
	[self finalizeDownloadWithIdentifier:downloadTask.taskIdentifier result:YES];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	[self finalizeDownloadWithIdentifier:task.taskIdentifier result:NO];
}

- (NSString *)localPathForRemotePackage:(Package *)remotePackage {
	return [[self.downloadsPath stringByAppendingPathComponent:remotePackage.package] stringByAppendingString:remotePackage.version];
}

- (BOOL)startDownloadingPackage:(Package *)remotePackage {
	NSString *key = [NSString stringWithFormat:@"%@ %@", remotePackage.package, remotePackage.version];
	if ([allPackages containsObject:key]) return NO;
	NSURL *url = remotePackage.debURL;
	NSURLSessionDownloadTask *downloadTask = [URLSession downloadTaskWithURL:url];
	tasks[@(downloadTask.taskIdentifier)] = @[
		[NSPointerArray weakObjectsPointerArray],
		key,
		downloadTask
	];
	[NSNotificationCenter.defaultCenter
		postNotificationName:DownloadDidStartNotification
		object:self
		userInfo:@{ @"taskID" : @(downloadTask.taskIdentifier), @"remotePackage" : remotePackage }
	];
	[downloadTask resume];
	return YES;
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
