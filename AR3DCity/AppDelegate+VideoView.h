//
//  AppDelegate+VideoView.h
//  AR3DCity
//
//  Created by frandfeng on 2018/7/26.
//  Copyright © 2018 JingHeQianCheng. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (VideoView)

- (void)initVideoView:(UIApplication *)application withOption:(NSDictionary *)launchOptions;
- (void)setVideoUrl:(NSURL *)url;
- (void)stopPlayVideo;
- (void)pausePlayVideo;
- (void)startPlayVideo;

@end
