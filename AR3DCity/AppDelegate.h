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
@class ZYMusic;
@class AVAudioPlayer;
@class CLLocation;
@class CLBeacon;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *unityWindow;
@property (strong, nonatomic) UnityAppController *unityController;
@property (strong, nonatomic) XMMovableButton *playButton;
//@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLBeacon *nearestBeacon;

- (void)startPlayingMusic;
- (void)bringButtonToFront;
- (void)hideButton;

@end

