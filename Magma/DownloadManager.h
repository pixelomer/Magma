//
//  DownloadManager.h
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DownloadDidCompleteNotification @"com.pixelomer.magma/DownloadDidComplete"
#define DownloadDidStartNotification @"com.pixelomer.magma/DownloadDidStart"

@class Package;

@protocol DownloadManagerDelegate<NSObject>
@required
- (void)downloadWithIdentifier:(NSUInteger)identifier didReceiveBytes:(int64_t)receivedBytes totalBytes:(int64_t)totalBytes;
- (void)downloadWithIdentifier:(NSUInteger)identifier didCompleteWithError:(NSString *)error;
@end

@interface DownloadManager : NSObject<NSURLSessionDelegate, NSURLSessionDownloadDelegate> {
	NSURLSession *URLSession;
	NSMutableDictionary<NSNumber *, NSArray<NSPointerArray *> *> *tasks;
	NSMutableArray<NSString *> *allPackages;
	//NSMutableDictionary<NSNumber *, NSArray *> *retryKeys;
}
+ (instancetype)sharedInstance;
- (int64_t)receivedBytesForIdentifier:(NSUInteger)identifier;
//- (BOOL)retryDownloadWithIdentifier:(NSUInteger)identifier;
- (int64_t)totalBytesForIdentifier:(NSUInteger)identifier;
- (NSString *)packageNameForTaskWithIdentifier:(NSUInteger)taskID;
- (NSString *)downloadsPath;
- (NSInteger)ongoingDownloadCount;
- (NSArray<NSNumber *> *)allTaskIdentifiers;
- (void)removeDelegate:(id<DownloadManagerDelegate>)oldDelegate forDownloadWithIdentifier:(NSUInteger)identifier;
- (void)addDelegate:(id<DownloadManagerDelegate>)newDelegate forDownloadWithIdentifier:(NSUInteger)identifier;
- (BOOL)startDownloadingPackage:(Package *)remotePackage;
@end
