//
//  AppDelegate.h
//  AR3DCity
//
//  Created by frandfeng on 17/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class UnityAppController;
@class XMMovableButton;
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIWindow *unityWindow;
@property (strong, nonatomic) UnityAppController *unityController;
@property (strong, nonatomic) XMMovableButton *playButton;
- (void)showUnityWindow;
- (void)hideUnityWindow;
@end

