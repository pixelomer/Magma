//
//  TextViewCell.h
//  Magma
//
//  Created by PixelOmer on 9.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextViewCell : UITableViewCell {
	UITextView *textView;
}
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (NSString *)textViewText;
- (void)setTextViewText:(NSString *)text;
@end
