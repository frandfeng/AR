//
//  PWApplicationUtils.h
//  AR3DCity
//
//  Created by frandfeng on 14/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PWApplicationUtils : NSObject

+ (instancetype)sharedInstance;
- (UIViewController *)activityViewController;

@end
