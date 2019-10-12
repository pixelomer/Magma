//
//  CatalystSearchProxy.h
//  Magma
//
//  Created by PixelOmer on 6.10.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#if TARGET_OS_MACCATALYST
#import <UIKit/UIKit.h>
#import "CatalystSplitViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CatalystSearchProxy : NSProxy<UISearchBarDelegate>
@property (nonatomic, weak) __kindof NSObject<UISearchBarDelegate> *delegate;
@property (nonatomic, weak) CatalystSplitViewController *splitViewController;
@end

NS_ASSUME_NONNULL_END
#endif
