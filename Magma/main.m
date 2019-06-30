#import "AppDelegate.h"
#import "Database.h"
#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) {
	@autoreleasepool {
		//Database.workingDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
		Database.workingDirectory = @"/var/mobile/Documents/magma";
		[Database.sharedInstance startLoadingDataIfNeeded];
		return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
	}
}