#import "PackageQueue.h"

@implementation PackageQueue

static PackageQueue *sharedInstance;

+ (instancetype)alloc {
    return sharedInstance ? nil : [super alloc];
}

+ (instancetype)sharedInstance {
    return sharedInstance = sharedInstance ?: [self new];
}

@end