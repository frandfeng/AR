//
//  AppDelegate+VideoView.m
//  AR3DCity
//
//  Created by frandfeng on 2018/7/26.
//  Copyright © 2018 JingHeQianCheng. All rights reserved.
//

#import "AppDelegate+VideoView.h"
#import "ZFPlayer.h"
#import "ZFAVPlayerManager.h"
#import "ZFPlayerControlView.h"
#import <objc/runtime.h>

static char VideoViewKey;
//1670/2208
const float widthRate = 0.75634;
//940/1242
const float heightRate = 0.75684;
//41/1242
const float top = 0.033;

@implementation AppDelegate (VideoView)

- (ZFPlayerController *)videoPlayer {
    if (objc_getAssociatedObject(self, &VideoViewKey)) {
        return objc_getAssociatedObject(self, &VideoViewKey);
    } else {
        return nil;
    }
}

- (void)setVideoPlayer:(ZFPlayerController *)videoPlayer {
    objc_setAssociatedObject(self, &VideoViewKey, videoPlayer, OBJC_ASSOCIATION_RETAIN);
}

- (void)initVideoView:(UIApplication *)application withOption:(NSDictionary *)launchOptions {
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    playerManager.scalingMode = ZFPlayerScalingModeAspectFill;
    ZFPlayerController *videoPlayer = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.containerView];
    videoPlayer.controlView = self.controlView;
    videoPlayer.containerView.hidden = YES;
    [self.unityWindow addSubview:videoPlayer.containerView];
    [self setVideoPlayer:videoPlayer];
}

- (void)setVideoUrl:(NSURL *)url {
    if (![url.absoluteString isEqualToString:self.videoPlayer.assetURL.absoluteString]) {
        self.videoPlayer.assetURL = url;
    }
}

- (void)stopPlayVideo {
    if (self.videoPlayer) {
        self.videoPlayer.containerView.hidden = YES;
        [self.unityWindow sendSubviewToBack:self.videoPlayer.containerView];
        [self.videoPlayer.currentPlayerManager stop];
        self.videoPlayer.assetURL = [NSURL URLWithString:@""];
    }
}

- (void)pausePlayVideo {
    if (self.videoPlayer) {
        self.videoPlayer.containerView.hidden = YES;
        [self.unityWindow sendSubviewToBack:self.videoPlayer.containerView];
        [self.videoPlayer.currentPlayerManager pause];
    }
}

- (void)startPlayVideo {
    if (self.videoPlayer) {
        self.videoPlayer.containerView.hidden = NO;
        [self.unityWindow bringSubviewToFront:self.videoPlayer.containerView];
        [self.videoPlayer.currentPlayerManager play];
    }
}

- (UIView *)containerView {
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    int screenHeight = [UIScreen mainScreen].bounds.size.height;
    int videoWidth = screenWidth * widthRate;
    int videoHeight = screenHeight * heightRate;
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake((screenWidth-videoWidth)/2, (screenHeight-videoHeight)/2+top*screenHeight, videoWidth, videoHeight)];
    return containerView;
}

- (ZFPlayerControlView *)controlView {
    ZFPlayerControlView *controlView = [ZFPlayerControlView new];
    return controlView;
}

@end
