//
//  SUStandardVersionComparator.h
//  Sparkle
//
//  Created by Andy Matuschak on 12/21/07.
//  Copyright 2007 Andy Matuschak. All rights reserved.
//
//  Modified by pixelomer on 07/02/19.
//  Original code can be found here: https://github.com/sparkle-project/Sparkle/blob/master/Sparkle/SUStandardVersionComparator.m
//

#ifndef SUSTANDARDVERSIONCOMPARATOR_H
#define SUSTANDARDVERSIONCOMPARATOR_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_ROOT_CLASS
@interface SUStandardVersionComparator
/*!
	Compares version strings through textual analysis.
	See the implementation for more details.
*/
+ (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB;
@end

NS_ASSUME_NONNULL_END

#endif
