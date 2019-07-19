//
//  LocalPackageOverviewController.h
//  Magma
//
//  Created by PixelOmer on 18.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalPackageOverviewController : UITableViewController {
	NSString *description;
}
@property (nonatomic, readonly, copy) NSString *packagePath;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *controlFile;
- (instancetype _Nullable)initWithPackageName:(NSString *)packageName;
@end

NS_ASSUME_NONNULL_END
