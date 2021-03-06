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

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIWindow *unityWindow;
@property (strong, nonatomic) UnityAppController *unityController;
@property (strong, nonatomic) XMMovableButton *playButton;
//@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLBeacon *nearestBeacon;
//判断歌曲播放过程中是否被电话等打断播放
@property (nonatomic, assign) BOOL isInterruptionByUnity;
//判断歌曲播放过程中是否被电话等打断播放
@property (nonatomic, assign) BOOL isInterruptionByUser;

//导航是否开启
@property (nonatomic, assign) BOOL navOpen;
//是否第一次更改导航状态
@property (nonatomic, assign) BOOL firstNavOpen;

- (void)startPlayingMusic;
- (void)bringButtonToFront:(BOOL)animated;
- (void)hideButton:(BOOL)animated;
- (void)audioPlayerInterruptionOfUnity:(BOOL)play;
- (void)audioPlayerInterruptionOfUser:(BOOL)play;

@end

