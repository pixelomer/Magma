#import <Foundation/Foundation.h>

@interface NSData(GZIP)
+ (BOOL)gunzipFile:(NSString *)inputFile toFile:(NSString *)outputFile;
@end
