#import <Foundation/Foundation.h>

@class Database;
@class Source;

NS_ASSUME_NONNULL_BEGIN

@interface Package : NSObject {
    NSString *_rawPackagesEntry;
}
@property (nonatomic, readonly, weak) Source * _Nullable source;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *rawPackage;
@property (nonatomic, readonly, copy) NSArray<NSString *> * _Nullable dependencies;
@property (nonatomic, readonly, copy) NSArray<NSString *> * _Nullable conflicts;
@property (nonatomic, readonly, copy) NSString * _Nullable shortDescription;
@property (nonatomic, readonly, copy) NSString * _Nullable longDescription;
@property (nonatomic, readonly, copy) NSDate * _Nullable firstDiscovery;
@property (nonatomic, readonly, assign) BOOL ignoresUpdates;
- (NSString *)rawPackagesEntry;
- (Database *)database;
- (NSString * _Nullable)getField:(NSString *)field;
- (instancetype)initWithDictionary:(NSDictionary *)dict source:(Source * _Nullable)source;
+ (NSArray<Package *> *)createPackagesUsingArray:(NSArray<NSDictionary<NSString *, NSString *> *> *)array source:(Source * _Nullable)source;
@end

// Implemented in +[Package load]
@interface Package(CommonKeys)
- (NSString * _Nullable)package;
- (NSString * _Nullable)name;
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
- (NSString * _Nullable)sha256;
@end

NS_ASSUME_NONNULL_END
