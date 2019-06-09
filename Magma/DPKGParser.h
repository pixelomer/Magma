/* DPKG Parser, taken from Obsidian v1.0 */

NS_ROOT_CLASS
@interface DPKGParser
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)parseFileContents:(NSString *)fileContents error:(NSError **)errorPt;
+ (NSDictionary<NSString *, NSString *> *)parsePackageEntry:(NSString *)fullEntry error:(NSError **)errorPt;
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)parseFileAtPath:(NSString *)path error:(NSError **)errorPt;
@end