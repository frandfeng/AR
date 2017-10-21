//
//  AppDelegate.m
//  AR3DCity
//
//  Created by frandfeng on 17/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import "AppDelegate.h"
#import "UnityAppController.h"
#import "iConsole.h"
#import "ZYPlayingViewController.h"
#import "XMMovableButton.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
- (UIWindow*)unityWindow {
    return self.unityController.window;
}
- (void)showUnityWindow {
    [self.unityWindow makeKeyWindow];
    self.window.hidden = YES;
}
- (void)hideUnityWindow {
    [self.window makeKeyWindow];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.unityController = [[UnityAppController alloc] init];
    [self.unityController application:application didFinishLaunchingWithOptions:launchOptions];
    self.unityController.window = [[iConsoleWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *tempVc = self.unityController.rootViewController;
    self.unityController.rootViewController = nil;
    self.unityController.window.rootViewController = tempVc;
    [self.unityController.window makeKeyAndVisible];
    [self addButton];
    return YES;
}
- (void)addButton {
    _playButton = [[XMMovableButton alloc] init];
    [_playButton setFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height-70, 60, 60)];
    _playButton.layer.cornerRadius = 30;
    _playButton.layer.masksToBounds=YES;
    [_playButton setImage:[UIImage imageNamed:@"smart_nav"] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(playButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [self.unityController.window addSubview:_playButton];
}
- (void)playButtonTouched {
    
}
- (void)applicationWillResignActive:(UIApplication *)application {
    [self.unityController applicationWillResignActive:application];
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self.unityController applicationDidEnterBackground:application];
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self.unityController applicationWillEnterForeground:application];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.unityController applicationDidBecomeActive:application];
    [self performSelector:@selector(bringButtonToFront) withObject:nil afterDelay:10.0];
}
- (void)applicationWillTerminate:(UIApplication *)application {
    [self.unityController applicationWillTerminate:application];
}
- (void)bringButtonToFront {
    [self.unityController.window bringSubviewToFront:_playButton];
}
@end
