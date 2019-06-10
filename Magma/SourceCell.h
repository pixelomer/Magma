#import <UIKit/UIKit.h>

@class Source;

@interface SourceCell : UITableViewCell {
	UIImageView *iconView;
}
@property (nonatomic, weak, setter=setSource:) Source *source;
- (void)setSource:(Source *)source;
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
@end