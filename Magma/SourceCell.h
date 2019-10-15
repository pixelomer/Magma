#import <UIKit/UIKit.h>

@class Source;

@interface SourceCell : UITableViewCell {
	UIProgressView *_progressView;
}
@property (nonatomic, weak, setter=setSource:) Source *source;
- (void)setSource:(Source *)source;
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
@end
