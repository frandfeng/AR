//
//  XMMovableButton.h
//  AlphaGoFinancial
//
//  Created by 万晓 on 16/7/26.
//  Copyright © 2016年 wxm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XMMovableButton : UIView

// 设置图片
- (void)setImageURL:(NSString *)url;
// 更新进度
- (void)updateProgressWithNumber:(NSUInteger)number;

@end
