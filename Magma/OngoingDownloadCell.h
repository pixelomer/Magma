//
//  OngoingDownloadCell.h
//  Magma
//
//  Created by PixelOmer on 12.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"

@interface OngoingDownloadCell : UITableViewCell<DownloadManagerDelegate>
@property (nonatomic, assign) NSUInteger identifier;
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
@end
