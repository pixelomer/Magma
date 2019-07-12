//
//  OngoingDownloadCell.m
//  Magma
//
//  Created by PixelOmer on 12.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "OngoingDownloadCell.h"

@implementation OngoingDownloadCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	return self;
}

- (void)downloadWithIdentifier:(NSUInteger)identifier didReceiveBytes:(int64_t)receivedBytes totalBytes:(int64_t)totalBytes {
	if (identifier != _identifier) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		self.detailTextLabel.text = [NSString stringWithFormat:@"%@ / %@",
			[NSByteCountFormatter stringFromByteCount:receivedBytes countStyle:NSByteCountFormatterCountStyleFile],
			[NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile]
		];
	});
}

- (void)resetProgress {
	self.detailTextLabel.text = [NSString stringWithFormat:@"%@ / %@",
		[NSByteCountFormatter stringFromByteCount:[DownloadManager.sharedInstance receivedBytesForIdentifier:_identifier] countStyle:NSByteCountFormatterCountStyleFile],
		[NSByteCountFormatter stringFromByteCount:[DownloadManager.sharedInstance totalBytesForIdentifier:_identifier] countStyle:NSByteCountFormatterCountStyleFile]
	];
}

- (void)downloadWithIdentifier:(NSUInteger)identifier didCompleteWithSuccess:(BOOL)success {
	if (identifier != _identifier) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		self.detailTextLabel.text = success ? @"Download completed successfully." : @"Download failed.";
	});
}

- (void)setIdentifier:(NSUInteger)identifier {
	_identifier = identifier;
	self.textLabel.text = [DownloadManager.sharedInstance packageNameForTaskWithIdentifier:identifier];
	[self resetProgress];
	[DownloadManager.sharedInstance addDelegate:self forDownloadWithIdentifier:identifier];
}

@end
