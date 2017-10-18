//
//  AppDelegate.m
//  AR3DCity
//
//  Created by frandfeng on 17/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import "AppDelegate.h"
#import "UnityAppController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
- (UIWindow*)unityWindow {
    return UnityGetMainWindow();
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
    self.window = self.unityWindow;
    [self.window makeKeyAndVisible];
    return YES;
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
}
- (void)applicationWillTerminate:(UIApplication *)application {
    [self.unityController applicationWillTerminate:application];
}
@end
