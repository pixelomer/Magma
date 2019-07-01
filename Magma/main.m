#import "AppDelegate.h"
#import "Database.h"
#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) {
	@autoreleasepool {
#if DEBUG
		Database.workingDirectory = @"/var/mobile/Documents/magma";
#else
		Database.workingDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#endif
		[Database.sharedInstance startLoadingDataIfNeeded];
		return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
	}
}