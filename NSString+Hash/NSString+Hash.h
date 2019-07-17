//
//  NSString+Hash.h
//  Magma
//
//  Created by PixelOmer on 17.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString(Hash)
+ (instancetype _Nullable)stringWithMD5HashOfFileAtPath:(NSString *)path;
+ (instancetype _Nullable)stringWithSHA256HashOfFileAtPath:(NSString *)path;
+ (instancetype _Nullable)stringWithSHA1HashOfFileAtPath:(NSString *)path;
+ (instancetype _Nullable)stringWithSHA512HashOfFileAtPath:(NSString *)path;
+ (instancetype _Nullable)stringWithHash:(NSString *)hash ofFileAtPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
