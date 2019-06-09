#import "AppDelegate.h"
#import "Database.h"
#import <Foundation/Foundation.h>

void *SecTaskCopyValueForEntitlement(void* task, CFStringRef entitlement, CFErrorRef _Nullable *error);
void *SecTaskCreateFromSelf(CFAllocatorRef allocator);

int main(int argc, char *argv[]) {
	@autoreleasepool {
		CFErrorRef error;
		NSString *documentRoot;
		NSNumber *value = (__bridge id)SecTaskCopyValueForEntitlement(SecTaskCreateFromSelf(NULL), (__bridge CFStringRef)@"com.apple.private.security.system-application", &error);
		if (error) {
			NSLog(@"SecTaskCopyValueForEntitlement error: %@", (__bridge id)error);
		}
		if (!error && value && [value isKindOfClass:[NSNumber class]] && value.boolValue) {
			NSLog(@"Magma is installed as a system app which means it is able to install packages.");
			documentRoot = [@"/var/mobile/Documents" stringByAppendingPathComponent:NSBundle.mainBundle.bundleIdentifier];
		}
		else {
			NSLog(@"Magma is installed as a regular app which means it is not able to install packages.");
			documentRoot = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
		}
		BOOL isDir;
		if (![NSFileManager.defaultManager fileExistsAtPath:documentRoot isDirectory:&isDir] || !isDir) {
			if (!isDir) [NSFileManager.defaultManager removeItemAtPath:documentRoot error:nil];
			[NSFileManager.defaultManager createDirectoryAtPath:documentRoot withIntermediateDirectories:NO attributes:nil error:nil];
		}
		Database.workingDirectory = documentRoot;
		[Database.sharedInstance startLoadingDataIfNeeded];
	}
	@autoreleasepool {
		return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
	}
}