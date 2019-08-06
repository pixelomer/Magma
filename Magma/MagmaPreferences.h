//
//  MagmaPreferences.h
//  Magma
//
//  Created by PixelOmer on 6.08.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MagmaPreferences : NSObject
+ (NSArray<NSString *> *)list;
+ (BOOL)assumesUTF8;
+ (NSString *)defaultArchitecture;
@end

NS_ASSUME_NONNULL_END
