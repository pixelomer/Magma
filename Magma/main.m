#import "AppDelegate.h"
#import <Foundation/Foundation.h>

void *SecTaskCopyValueForEntitlement(void* task, CFStringRef entitlement, CFErrorRef _Nullable *error);
void *SecTaskCreateFromSelf(CFAllocatorRef allocator);

int main(int argc, char *argv[]) {
	@autoreleasepool {
		CFErrorRef error;
		NSNumber *value = (__bridge id)SecTaskCopyValueForEntitlement(SecTaskCreateFromSelf(NULL), (__bridge CFStringRef)@"com.apple.private.security.system-application", &error);
		if (error) {
			NSLog(@"SecTaskCopyValueForEntitlement error: %@", (__bridge id)error);
		}
		if (!error && value && [value isKindOfClass:[NSNumber class]] && value.boolValue) {
			NSLog(@"Able to install packages.");
		}
		else {
			NSLog(@"Not able to install packages.");
		}
		return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
	}
}