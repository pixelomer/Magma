//
//  FilesViewController.h
//  Magma
//
//  Created by PixelOmer on 19.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

NS_ASSUME_NONNULL_BEGIN

@interface FilesViewController : UITableViewController<QLPreviewControllerDataSource> {
	NSString *newFile;
	NSArray<NSString *> *filenames;
	NSArray<NSArray *> *fileDetails;
	UIRefreshControl *refreshControl;
}
@property (nonatomic, readonly, copy) NSString *path;
- (instancetype _Nullable)initWithPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
