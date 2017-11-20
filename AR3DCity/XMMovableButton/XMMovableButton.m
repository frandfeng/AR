//
//  XMMovableButton.m
//  AlphaGoFinancial
//
//  Created by 万晓 on 16/7/26.
//  Copyright © 2016年 wxm. All rights reserved.
//

#import "XMMovableButton.h"

static int kLineWidth = 3;

@interface XMMovableButton()

//是否移动
@property (nonatomic,assign) BOOL isMoved;
@property (nonatomic,strong) UIImageView *picImageView;
@property (nonatomic,strong) CAShapeLayer *outLayer;
@property (nonatomic,strong) CAShapeLayer *progressLayer;
@property (nonatomic,strong) CAShapeLayer *circleLayer;
@property (nonatomic,assign) float progress;

@end

@implementation XMMovableButton

-(instancetype)initWithFrame:(CGRect)frame {
    if (self=[super initWithFrame:frame]) {
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.picImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.picImageView];


        self.outLayer = [CAShapeLayer layer];
        CGRect rect = {0, 0, frame.size.width, frame.size.height};
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
        self.outLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.outLayer.lineWidth = kLineWidth;
        self.outLayer.fillColor =  [UIColor clearColor].CGColor;
        self.outLayer.lineCap = kCALineCapRound;
        self.outLayer.path = path.CGPath;
        [self.layer addSublayer:self.outLayer];


        self.progressLayer = [CAShapeLayer layer];
        self.progressLayer.fillColor = [UIColor clearColor].CGColor;
        self.progressLayer.strokeColor = [UIColor colorWithRed:87/255.0 green:177/255.0 blue:249/255.0 alpha:1.0].CGColor;
        self.progressLayer.lineWidth = kLineWidth;
        self.progressLayer.lineCap = kCALineCapRound;
        self.progressLayer.path = path.CGPath;
        [self.layer addSublayer:self.progressLayer];
        
        
        self.circleLayer = [CAShapeLayer layer];
        CGRect rect1 = {frame.size.width/3, frame.size.height/3,
            frame.size.width/3, frame.size.height/3};
        UIBezierPath *path1 = [UIBezierPath bezierPathWithOvalInRect:rect1];
        self.circleLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.circleLayer.lineWidth = kLineWidth;
        self.circleLayer.fillColor =  [UIColor clearColor].CGColor;
        self.circleLayer.lineCap = kCALineCapRound;
        self.circleLayer.path = path1.CGPath;
        
//        self.layer.shadowColor = [UIColor greenColor].CGColor;//阴影颜色
//        self.layer.shadowOffset = CGSizeMake(0, 0);//偏移距离
//        self.layer.shadowOpacity = 0.5;//不透明度
//        self.layer.shadowRadius = frame.size.width;//半径

//        self.transform = CGAffineTransformMakeRotation(-M_PI_2);
//        self.picImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    return self;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [super touchesMoved:touches withEvent:event];
    
    UITouch * touch = [touches anyObject];
    
    //本次触摸点
    CGPoint current = [touch locationInView:self];
    
    //上次触摸点
    CGPoint previous = [touch previousLocationInView:self];
    
    CGPoint center = self.center;
    
    //中心点移动触摸移动的距离
    center.x += current.x - previous.x;
    center.y += current.y - previous.y;
    
    //限制移动范围
    CGFloat screenWidth  = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    NSLog(@"touchesMoved width %lf, height %lf", screenWidth, screenHeight);
    
    CGFloat xMin = self.frame.size.width  * 0.5f;
    CGFloat xMax = screenWidth  - xMin;
    
    CGFloat yMin = self.frame.size.height * 0.5f;
    CGFloat yMax = screenHeight - self.frame.size.height * 0.5f;
    
    if (center.x >= xMax) center.x = xMax;
    if (center.x < xMin) center.x = xMin;
    
    if (center.y >= yMax) center.y = yMax;
    if (center.y < yMin) center.y = yMin;
    
    self.center = center;
    
    //移动距离大于0.5才判断为移动了(提高容错性)
    if (current.x-previous.x>=0.5 || current.y - previous.y>=0.5) {
        self.isMoved = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.isMoved) {
        //如果没有移动，则调用父类方法，触发button的点击事件
        [super touchesEnded:touches withEvent:event];
    }
    CGPoint center = self.center;
    //限制移动范围
    CGFloat screenWidth  = [UIScreen mainScreen].bounds.size.width;
    NSLog(@"touchesEnded width %lf", screenWidth);
    
    CGFloat xMin = self.frame.size.width  * 0.5f;
    CGFloat xMax = screenWidth  - xMin;
    
    if (center.x < xMax/2) center.x = xMin;
    if (center.x > xMax/2) center.x = xMax;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.center = center;
    }];
    
    self.isMoved = NO;
    
//    if (!self.dockable) return;
    
    //回到一定范围
//    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
//    CGFloat           x = self.frame.size.width * 0.5f;
//    
//    [UIView animateWithDuration:0.25f animations:^{
//        CGPoint center = self.center;
//        center.x = self.center.x > screenWidth * 0.5f ? screenWidth - x : x;
//        self.center = center;
//    }];
    
    //关闭高亮状态
//    [self setHighlighted:NO];
}

- (void)updateProgressWithNumber:(NSUInteger)number {
    if (number==0 && [self.circleLayer superlayer]) {
        
    } else if (number!=0 && ![self.circleLayer superlayer]) {
        
    }
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        float progress = number / 100.0;
        self.picImageView.transform = CGAffineTransformMakeRotation(M_PI*progress*10);
        self.progressLayer.strokeEnd =  progress;
    } completion:nil];
    float progress = number / 100.0;
    CABasicAnimation *pathAnima = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnima.duration = 1.0f;
    pathAnima.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    pathAnima.fromValue = [NSNumber numberWithFloat:_progress];
    _progress = progress;
    pathAnima.toValue = [NSNumber numberWithFloat:_progress];
    pathAnima.fillMode = kCAFillModeForwards;
    pathAnima.removedOnCompletion = NO;
    [self.progressLayer addAnimation:pathAnima forKey:@"strokeEndAnimation"];
}

- (void)setImagePic:(UIImage *)image centerCircle:(BOOL)showCircle {
    _picImageView.image = image;
    if (showCircle) {
        [self.layer addSublayer:self.circleLayer];
    } else {
        [self.circleLayer removeFromSuperlayer];
    }
}

@end
