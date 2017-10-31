//
//  PWApplicationUtils.h
//  AR3DCity
//
//  Created by frandfeng on 14/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CLLocation;

@interface PWApplicationUtils : NSObject

+ (instancetype)sharedInstance;
+ (int)getIndexOfMusicForLocation:(CLLocation *)location;
+ (UIImage*)getSquareImage:(UIImage *)image RangeCGRect:(CGRect)range centerBool:(BOOL)centerBool;
+ (UIImage*)getClearRectImage:(UIImage*)image;
- (UIViewController *)activityViewController;

@end
