//
//  DownloadManager.m
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "DownloadManager.h"
#import "AppDelegate.h"

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
	return sharedInstance ? nil : [self sharedInstance];
}

- (instancetype)init {
	return [super init];
}

@end
