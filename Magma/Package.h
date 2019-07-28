#import <Foundation/Foundation.h>

@class Database;
@class Source;

NS_ASSUME_NONNULL_BEGIN

@interface Package : NSObject {
	NSString *_package;
	NSString *_version;
	NSString *_section;
}
@property (nonatomic, readonly, assign) NSRange range;
@property (nonatomic, readonly, weak) Source * _Nullable source;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *rawPackage;
@property (nonatomic, readonly, copy) NSArray<NSString *> * _Nullable dependencies;
@property (nonatomic, readonly, copy) NSArray<NSString *> * _Nullable conflicts;
@property (nonatomic, readonly, copy) NSString * _Nullable shortDescription;
@property (nonatomic, readonly, copy) NSString * _Nullable longDescription;
@property (nonatomic, readonly, copy) NSDate * _Nullable firstDiscovery;
@property (nonatomic, readonly, copy) NSURL *debURL;
@property (nonatomic, assign) NSStringEncoding encoding;
- (BOOL)parse;
- (NSString *)version;
- (NSString *)section;
- (NSString *)package;
- (Database *)database;
- (NSArray * _Nullable)tags;
- (NSComparisonResult)compare:(Package *)package;
- (NSString * _Nullable)objectForKeyedSubscript:(NSString *)key; // package[@"abc"] = package.rawPackage[@"abc"]
- (NSString * _Nullable)getField:(NSString *)field;
- (instancetype)initWithRange:(NSRange)range source:(Source * _Nullable)source;
+ (NSArray *)latestSortedPackagesFromPackageArray:(NSArray *)array;
@end

// Implemented in +[Package load], -[Package parse] needs to be called before accessing these
@interface Package(CommonKeys)
- (NSString * _Nullable)author;
- (NSString * _Nullable)maintainer;
- (NSString * _Nullable)description;
- (NSString * _Nullable)md5sum;
- (NSString * _Nullable)sha1;
- (NSString * _Nullable)sha256;
- (NSString * _Nullable)version;
- (NSString * _Nullable)filename;
- (NSString * _Nullable)architecture;
- (NSString * _Nullable)section;
- (NSString * _Nullable)name;
- (NSString * _Nullable)sha512;
@end

NS_ASSUME_NONNULL_END
