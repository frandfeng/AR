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
#import "ZYMusic.h"
#import "ZYMusicTool.h"
#import "ZYAudioManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <notify.h>
#import "ZYLrcLine.h"
#import "LocationManager.h"
#import "ZYPlayingViewController.h"
#import "PWApplicationUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import "PWUnityMsgManager.h"
#import "AppDelegate+VideoView.h"

@interface AppDelegate () <AVAudioPlayerDelegate, CLLocationManagerDelegate>

//正在播放的音频
@property (nonatomic, strong) ZYMusic *playingMusic;
//音频播放器
@property (nonatomic, strong) AVAudioPlayer *player;
//判断歌曲播放过程中是否被电话等打断播放
@property (nonatomic, assign) BOOL isInterruption;

//定位的定时器
@property (nonatomic, strong) NSTimer *locTimer;

//更新UI的定时器
@property (nonatomic, strong) NSTimer *uiTimer;

//锁屏图片视图,用来绘制带歌词的image
@property (nonatomic, strong) UIImageView *lrcImageView;
//最后一次锁屏之后的歌词海报
@property (nonatomic, strong) UIImage *lastImage;
//用来显示锁屏歌词
@property (nonatomic, strong) UITextView *lockScreenTableView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *knowBeacons;
@property (nonatomic, strong) NSMutableArray *beaconRegions;


@property (nonatomic, assign) int locIndex;
@property (nonatomic, assign) int sameTimes;
@property (nonatomic, assign) int times;

@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;

@end

@implementation AppDelegate
- (UIWindow*)unityWindow {
    return self.unityController.window;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.unityController = [[UnityAppController alloc] init];
    [self.unityController application:application didFinishLaunchingWithOptions:launchOptions];
    
//    如果需要手机打印log的情况
//    self.unityController.window = [[iConsoleWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    UIViewController *tempVc = self.unityController.rootViewController;
//    self.unityController.rootViewController = nil;
//    self.unityController.window.rootViewController = tempVc;
//    [self.unityController.window makeKeyAndVisible];
    
    self.unityController.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *tempVc = self.unityController.rootViewController;
    self.unityController.rootViewController = nil;
    self.unityController.window.rootViewController = tempVc;
    [self.unityController.window makeKeyAndVisible];
    
    [self initVideoView:application withOption:launchOptions];
    [self addLocTimer];
    [self addButton];
    [self createRemoteCommandCenter];
//    _currentLocation = [[CLLocation alloc] init];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    self.locationManager.activityType = CLActivityTypeFitness;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if (CLLocationManager.authorizationStatus != kCLAuthorizationStatusAuthorizedWhenInUse) {
        [_locationManager requestWhenInUseAuthorization];
    }
    _isInterruptionByUnity = false;
    _isInterruptionByUser = false;
    _knowBeacons = [NSMutableArray array];
    _beaconRegions = [NSMutableArray array];
    _locIndex = -1;
    _sameTimes = 0;
    _times = 0;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self cutImageAndSave];
    });
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(startRangeIbeacons) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return YES;
}

- (void)startRangeIbeacons {
    NSArray *musics = [ZYMusicTool musics];
    for (ZYMusic *music in musics) {
        if (music.uuid && ![music.uuid isEqualToString:@""])  {
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:music.uuid];
            CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:music.identifier];
            beaconRegion.notifyOnExit = YES;
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyEntryStateOnDisplay = YES;
            [_beaconRegions addObject:beaconRegion];
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            [self.locationManager requestStateForRegion:beaconRegion];
            NSLog(@"start ranging uuid: %@, identifier: %@", music.uuid, music.identifier);
        }
    }
}

- (void)cutImageAndSave {
    BOOL cutFinish = [[NSUserDefaults standardUserDefaults] boolForKey:@"cutFinish"];
    if (cutFinish) return;
    
    UIImage *image = [UIImage imageNamed:@"zhinengdaoyouditu.jpg"];
    NSString *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    for (int i=-1; i<2; i++) {
        int scale = 2 << i;
        if (i==-1) {
            scale = 1;
        }
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width/scale, image.size.height/scale)];
        imageView.image = image;
        //    [self.view addSubview:imageView];
        CGFloat WH = 256;
        CGSize size = imageView.frame.size;
        
        //ceil 向上取整
        NSInteger rows = ceil(size.height / WH);
        NSInteger cols = ceil(size.width / WH);
        [iConsole log:@"cut images scale:%d, rows:%d, cols:%d", scale, (int)rows, (int)cols];
        for (NSInteger y = 0; y < rows; ++y) {
            for (NSInteger x = 0; x < cols; ++x) {
                @autoreleasepool {
                    UIImage *subImage = [self captureView:imageView frame:CGRectMake(x*WH, y*WH, WH, WH)];
                    NSString *path = [NSString stringWithFormat:@"%@/yiheyuan-%02dx-%02ld-%02ld.png",filePath,scale,y,x];
                    [UIImagePNGRepresentation(subImage) writeToFile:path atomically:YES];
                    NSLog(@"save path: %@", path);
                }
                if (y==rows-1 && x==cols-1) {
                    NSLog(@"cutImageAndSave finish");
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"cutFinish"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
        }
    }
}


/** 切图 */
- (UIImage*)captureView:(UIView *)theView frame:(CGRect)fra{
    //开启图形上下文 将heView的所有内容渲染到图形上下文中
    UIGraphicsBeginImageContext(theView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [theView.layer renderInContext:context];
    
    //获取图片
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRef ref = CGImageCreateWithImageInRect(img.CGImage, fra);
    UIImage *i = [UIImage imageWithCGImage:ref];
    CGImageRelease(ref);
    
    return i;
}

- (void)toastChange:(NSString *)name {
    CGRect buttonFrame = _playButton.frame;
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:15];
    label.frame = CGRectMake(buttonFrame.origin.x-10, buttonFrame.origin.y-30, 90, 20);
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = name;
    label.alpha = 0;
    [self.unityController.window addSubview:label];
    [UIView animateWithDuration:2.0 animations:^{
        label.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:2.0 animations:^{
            label.alpha = 0;
        } completion:^(BOOL finished) {
            [label removeFromSuperview];
        }];
    }];
}

- (void)addButton {
    if (_playButton) return;
    _playButton = [[XMMovableButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-70, 70, 70)];
    [_playButton setImagePic:[UIImage imageNamed:@"smart_nav"] centerCircle:NO];
    [_playButton updateProgressWithNumber:0];
    [_playButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playButtonTouched:)]];
    [self hideButton:NO];
    [self.unityWindow addSubview:_playButton];
}
- (void)playButtonTouched:(UITapGestureRecognizer *)gestureRecognizer {
    ZYPlayingViewController *vc = [[ZYPlayingViewController alloc] init];
    [[PWApplicationUtils sharedInstance].activityViewController presentViewController:vc animated:YES completion:nil];
}
//-(void)playMovieAtURL:(NSURL*)theURL
//{
//    VideoPlayerViewController *playerView = [[VideoPlayerViewController alloc] initWithContentURL:theURL];
//    playerView.view.frame = self.unityWindow.frame;//全屏播放（全屏播放不可缺）
//    playerView.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;//全屏播放（全屏播放不可缺）
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(myMovieFinishedCallback:)
//                                                 name:MPMoviePlayerPlaybackDidFinishNotification
//                                               object:playerView];
//    [playerView.moviePlayer play];
//    [[[PWApplicationUtils sharedInstance] activityViewController] presentMoviePlayerViewControllerAnimated:playerView];
//}
//
//// When the movie is done, release the controller.
//-(void)myMovieFinishedCallback:(NSNotification*)aNotification
//{
//    VideoPlayerViewController* theMovie = [aNotification object];
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:MPMoviePlayerPlaybackDidFinishNotification
//                                                  object:theMovie];
//}
- (void)applicationWillResignActive:(UIApplication *)application {
    [self.unityController applicationWillResignActive:application];
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self.unityController applicationDidEnterBackground:application];
    _bgTask = [application beginBackgroundTaskWithName:@"MyTask" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [self startRangeIbeacons];
        [application endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task, preferably in chunks.
        
        [application endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    });
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self.unityController applicationWillEnterForeground:application];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.unityController applicationDidBecomeActive:application];
//    [self buttonAnimatedToFront];
//    [self performSelector:@selector(buttonAnimatedToFront) withObject:nil afterDelay:10.0];
    
}
//- (void)buttonAnimatedToFront {
//    _playButton.hidden = NO;
//    _playButton.alpha = 0;
//    _playButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-70, 70, 70);
//    [self.unityController.window bringSubviewToFront:_playButton];
//    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
////        _playButton.transform = CGAffineTransformMakeRotation( (360.1) * M_PI / 180.0);
//        _playButton.alpha = 1;
//        _playButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-80, [UIScreen mainScreen].bounds.size.height-70, 70, 70);
//    } completion:^(BOOL finished) {
//        [self.unityController.window bringSubviewToFront:_playButton];
//        [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
//            //        _playButton.transform = CGAffineTransformMakeRotation( (360.1) * M_PI / 180.0);
//            _playButton.alpha = 1;
//            _playButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-80, [UIScreen mainScreen].bounds.size.height-70, 70, 70);
//        } completion:^(BOOL finished) {
//            [self.unityController.window bringSubviewToFront:_playButton];
//        }];
//        [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
//            _playButton.transform = CGAffineTransformMakeRotation(M_PI);
//        } completion:^(BOOL finished) {
//            [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
//                _playButton.transform = CGAffineTransformMakeRotation(2*M_PI);
//            } completion:nil];
//        }];
//    }];
//}
- (void)applicationWillTerminate:(UIApplication *)application {
    [self.unityController applicationWillTerminate:application];
}
- (void)bringButtonToFront:(BOOL)animated {
    if (animated) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(animateButtonFront) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    } else {
        _playButton.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.unityController.window bringSubviewToFront:_playButton];
        });
    }
    NSLog(@"bringButtonToFront %lf, %lf", _playButton.frame.origin.x, _playButton.frame.origin.y);
}

- (void)animateButtonFront {
    _playButton.frame = CGRectMake(-70, [UIScreen mainScreen].bounds.size.height-70, 70, 70);
    _playButton.alpha = 0;
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        //        _playButton.transform = CGAffineTransformMakeRotation( (360.1) * M_PI / 180.0);
        _playButton.alpha = 1;
        _playButton.hidden = NO;
        _playButton.frame = CGRectMake(10, [UIScreen mainScreen].bounds.size.height-70, 70, 70);
    } completion:^(BOOL finished) {
        _playButton.frame = CGRectMake(10, [UIScreen mainScreen].bounds.size.height-70, 70, 70);
        _playButton.alpha = 1;
        _playButton.hidden = NO;
    }];
    [UIView animateWithDuration:2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        _playButton.transform = CGAffineTransformMakeRotation(M_PI);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            _playButton.transform = CGAffineTransformMakeRotation(2*M_PI);
        } completion:nil];
    }];
}

- (void)hideButton:(BOOL)animated {
    _playButton.hidden = YES;
}

#pragma mark ---定位定时器
- (void)addLocTimer {
    //在新增定时器之前，先移除之前的定时器
    [self removeLocTimer];
    self.locTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(loc) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.locTimer forMode:NSRunLoopCommonModes];
}
- (void)removeLocTimer {
    [self.locTimer invalidate];
    self.locTimer = nil;
}

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    [iConsole log:@"locationManager didEnterRegion %@", (CLBeaconRegion *)region.identifier];
    [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region {
    [iConsole log:@"locationManager didExitRegion %@", (CLBeaconRegion *)region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    [iConsole log:@"monitoringDidFailForRegion - error: %@", [error localizedDescription]];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    [iConsole log:@"didDetermineState - region: %@", (CLBeaconRegion *)region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    for (CLBeacon *beacon in beacons) {
        if (beacon.proximity != CLProximityUnknown) {
            BOOL exist = NO;
            for (int i=0; i<_knowBeacons.count; i++) {
                CLBeacon *knowBeacon = _knowBeacons[i];
                if ([beacon.proximityUUID.UUIDString isEqualToString:knowBeacon.proximityUUID.UUIDString]) {
                    _knowBeacons[i] = beacon;
                    exist = YES;
                    break;
                }
            }
            if (!exist) {
                exist = NO;
                [_knowBeacons addObject:beacon];
            }
        }
    }
    _nearestBeacon = nil;
    for (CLBeacon *beacon in _knowBeacons) {
        if (_nearestBeacon==nil) {
            _nearestBeacon = beacon;
        } else {
            if (_nearestBeacon.accuracy > beacon.accuracy) {
                _nearestBeacon = beacon;
            }
        }
    }
    if (_nearestBeacon!=nil) {
        int index = [PWApplicationUtils getIndexOfMusicForBeacon:_nearestBeacon];
        if (_nearestBeacon.accuracy<1) {
            if (index == _locIndex) {
                _sameTimes ++;
            } else {
                _locIndex = index;
                _sameTimes = 0;
            }
            if (index >= 0 && _sameTimes == 5) {
                _sameTimes = 0;
                if (self.isInterruption || self.isInterruptionByUnity || self.isInterruptionByUser) {
                    return;
                }
                if (![[NSUserDefaults standardUserDefaults] boolForKey:@"cutFinish"]) {
                    return;
                }
                ZYMusic *music = [ZYMusicTool musics][index];
                [ZYMusicTool setPlayingMusic:music];
                
                if (_navOpen && (self.playingMusic != [ZYMusicTool playingMusic] || _firstNavOpen)) {
                    _firstNavOpen = NO;
                    [[PWUnityMsgManager sharedInstance] sendMsg2UnityOfType:@"OnARNavigateChanged" andValue:[NSString stringWithFormat:@"{\"params\":{\"identifier\":\"%@\"}}", _nearestBeacon.proximityUUID]];
                }
                
                [self startPlayingMusic];
            }
        } else {
            _locIndex = -1;
            _sameTimes = 0;
        }
    }
    
    
//    weakSelf.currentLocation = [locations firstObject];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSNotificationNameLocation" object:_currentLocation userInfo:nil];
//    [iConsole info:@"获取到地理位置 %lf, %lf", weakSelf.currentLocation.coordinate.latitude, weakSelf.currentLocation.coordinate.longitude];
//    int index = [PWApplicationUtils getIndexOfMusicForLocation:_currentLocation];
//    if (index >= 0) {
//        ZYMusic *music = [ZYMusicTool musics][index];
//        [ZYMusicTool setPlayingMusic:music];
//        [self startPlayingMusic];
//    }
}

- (void)loc {
//    LocationManager *locManager = [LocationManager sharedLocationManager];
//    __weak __typeof__(self) weakSelf = self;
//
//    [iConsole info:@"开始请求位置信息。。。"];
//    [locManager startLocation:^(NSArray<CLLocation *> *locations) {
//        if (locations!=nil&&locations.count>0) {
//            weakSelf.currentLocation = [locations firstObject];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"NSNotificationNameLocation" object:_currentLocation userInfo:nil];
//            [iConsole info:@"获取到地理位置 %lf, %lf", weakSelf.currentLocation.coordinate.latitude, weakSelf.currentLocation.coordinate.longitude];
//            int index = [PWApplicationUtils getIndexOfMusicForLocation:_currentLocation];
//            if (index >= 0) {
//                ZYMusic *music = [ZYMusicTool musics][index];
//                [ZYMusicTool setPlayingMusic:music];
//                [self startPlayingMusic];
//            }
//        }
//    }];
    
}

//锁屏界面开启和监控远程控制事件
- (void)createRemoteCommandCenter {
    //远程控制命令中心 iOS 7.1 之后  详情看官方文档：https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player pause];
        _isInterruptionByUser = YES;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player play];
        _isInterruptionByUser = NO;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.changePlaybackRateCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    //在控制台拖动进度条调节进度（仿QQ音乐的效果）
    [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
        self.player.currentTime = playbackPositionEvent.positionTime;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

//开始播放音乐,播放前需要先设置要播放的音乐[ZYMusicTool playingMusic]
- (void)startPlayingMusic {
    if (self.playingMusic == [ZYMusicTool playingMusic]) {
        [iConsole log:@"相同的景点，不需要播放新音频"];
        return;
    }
    [self resetPlayingMusic];
    [iConsole log:@"开始播放新音频"];
    if (_nearestBeacon) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NSNotificationNameLocation" object:_nearestBeacon userInfo:nil];
    }
    
    // 设置所需要的数据
    self.playingMusic = [ZYMusicTool playingMusic];
//    self.iconView.image = [UIImage imageNamed:@"yiheyuan"];
//    self.songLabel.text = self.playingMusic.name;
    
    [self toastChange:self.playingMusic.name];
    //开发播放音乐
    [[ZYAudioManager defaultManager] playMusic:self.playingMusic.musicId];
    self.player = [[ZYAudioManager defaultManager] player:self.playingMusic.musicId];
    self.player.delegate = self;
    
//    self.timeLabel.text = [self stringWithTime:self.player.duration];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSNotificationNameStartPlay" object:nil];
    
    [self addUITimer];
    //切换歌词
    //    self.lrcView.fileName = self.playingMusic.lrcname;
//    self.playOrPauseButton.selected = YES;
}

/**
 *  添加定时器，更新滑块进度，锁屏页面进度
 */
- (void)addUITimer {
    if (![self.player isPlaying]) return;
    
    //在新增定时器之前，先移除之前的定时器
    [self removeUITimer];
    
    [self updateUI];
    self.uiTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.uiTimer forMode:NSRunLoopCommonModes];
}

/**
 *  移除定时器
 */
- (void)removeUITimer {
    [self.uiTimer invalidate];
    self.uiTimer = nil;
}

/**
 *  触发定时器
 */
- (void)updateUI {
    double temp = self.player.currentTime / self.player.duration;
//    self.sliderView.value = temp;
    //    self.slider.x = temp * (self.view.width - self.slider.width);
    
    float totalTime = self.player.duration;
    float currentTime = self.player.currentTime;
    
//    [self.playButton setTitle:[NSString stringWithFormat:@"%d", (int)(temp*100)] forState:UIControlStateNormal];
    [_playButton updateProgressWithNumber:temp*100];
    if (self.player.currentTime<1) {
        NSString *icon = self.playingMusic.icon;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Data/Raw/Texture2d/%@", icon] ofType:@"png"];
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        CGSize size =image.size;
        
        float imageSize;
        
        NSLog(@"size==height%f====width%f",size.height,size.width);
        
        if(size.height>= size.width) {
            
            imageSize = size.width;
            
        }else{
            
            imageSize = size.height;
            
        }
        UIImage *squareImage = [PWApplicationUtils getSquareImage:image RangeCGRect:CGRectMake(0, 0, imageSize, imageSize) centerBool:YES];
        [_playButton setImagePic:[PWApplicationUtils getClearRectImage:squareImage] centerCircle:YES];
    }
    
//    self.timeLabel.text = [self stringWithTime:totalTime];
//    self.progressLabel.text = [self stringWithTime:currentTime];
    
    //监听锁屏状态 lock=1则为锁屏状态
    uint64_t locked;
    __block int token = 0;
    notify_register_dispatch("com.apple.springboard.lockstate",&token,dispatch_get_main_queue(),^(int t){
    });
    notify_get_state(token, &locked);
    
    //监听屏幕点亮状态 screenLight = 1则为变暗关闭状态
    uint64_t screenLight;
    __block int lightToken = 0;
    notify_register_dispatch("com.apple.springboard.hasBlankedScreen",&lightToken,dispatch_get_main_queue(),^(int t){
    });
    notify_get_state(lightToken, &screenLight);
    
    BOOL isShowLyricsPoster = NO;
    // NSLog(@"screenLight=%llu locked=%llu",screenLight,locked);
    if (screenLight == 0 && locked == 1) {
        //点亮且锁屏时
        isShowLyricsPoster = YES;
    } else if(screenLight) {
        return;
    }
    //展示锁屏歌曲信息，上面监听屏幕锁屏和点亮状态的目的是为了提高效率
    [self showLockScreenTotaltime:totalTime andCurrentTime:currentTime andLyricsPoster:isShowLyricsPoster];
}

//展示锁屏歌曲信息：图片、歌词、进度、演唱者
- (void)showLockScreenTotaltime:(float)totalTime andCurrentTime:(float)currentTime andLyricsPoster:(BOOL)isShow {
    
    // 播放信息中心
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    
    // 初始化播放信息
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    // 专辑名称
    info[MPMediaItemPropertyAlbumTitle] = self.playingMusic.name;
    // 歌手
//    info[MPMediaItemPropertyArtist] = self.playingMusic.musicId;
    // 歌曲名称
//    info[MPMediaItemPropertyTitle] = [NSString stringWithFormat:@"%f,@%f", _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude];
    // 设置图片
    //    info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:self.playingMusic.icon]];
    // 设置持续时间（歌曲的总时间）
    info[MPMediaItemPropertyPlaybackDuration] = @(self.player.duration);
    // 设置当前播放进度
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.player.currentTime);
    
    // 切换播放信息
    //    center.nowPlayingInfo = info;
    
    // 远程控制事件 Remote Control Event
    // 加速计事件 Motion Event
    // 触摸事件 Touch Event
    
    // 开始监听远程控制事件
    // 成为第一响应者（必备条件）
    [self becomeFirstResponder];
    // 开始监控
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Data/Raw/Texture2d/%@", self.playingMusic.icon] ofType:@"png"];
    UIImage *lrcImage = [UIImage imageWithContentsOfFile:filePath];
    if (isShow) {
        
        //制作带歌词的海报
        if (!_lrcImageView) {
            _lrcImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 480,480)];
        }
        if (!_lockScreenTableView) {
            _lockScreenTableView = [[UITextView alloc] initWithFrame:CGRectMake(0, 240, 480, 240)];
            _lockScreenTableView.editable = NO;
            _lockScreenTableView.backgroundColor = [UIColor clearColor];
            _lockScreenTableView.font = [UIFont systemFontOfSize:26];
        }
        if ([_playingMusic.detail hasSuffix:@".lrc"]) {
            NSMutableArray *lrcLines = [ZYLrcLine lrcLinesWithFileName:_playingMusic.detail];
            NSString *detail = @"";
            for ( int i = (int)(lrcLines.count - 1); i >= 0 ;i--) {
                ZYLrcLine * lrc = lrcLines[i];
                if (lrc.time && lrc.word) {
                    if ([self timeIntervalFromTime:lrc.time] < currentTime) {
                        detail = lrc.word;
                        break;
                    }
                }
            }
            _lockScreenTableView.text = detail;
        } else {
            double rate = self.player.currentTime / self.player.duration;
            double textLength = [_playingMusic.detail length];
            double pointer = rate * textLength;
            _lockScreenTableView.text = [_playingMusic.detail substringFromIndex:(int)pointer];
        }
        //主要为了把歌词绘制到图片上，已达到更新歌词的目的
        //[_lrcImageView addSubview:self.lockScreenTableView];
        _lrcImageView.image = lrcImage;
        _lrcImageView.backgroundColor = [UIColor blackColor];
        
        //获取添加了歌词数据的海报图片
        UIGraphicsBeginImageContextWithOptions(_lrcImageView.frame.size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [_lrcImageView.layer renderInContext:context];
        lrcImage = UIGraphicsGetImageFromCurrentImageContext();
        _lastImage = lrcImage;
        UIGraphicsEndImageContext();
        
    }else{
        if (_lastImage) {
            lrcImage = _lastImage;
        }
    }
    
    if (lrcImage) {
        //设置显示的海报图片
        info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:lrcImage];
    }
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
    
}

- (NSTimeInterval)timeIntervalFromTime:(NSString *)time {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"mm:ss.SS"];
    
    NSDate * date1 = [df dateFromString:time];
    NSDate *date2 = [df dateFromString:@"00:00.00"];
    NSTimeInterval  interval1 = [date1  timeIntervalSince1970];
    NSTimeInterval  interval2 = [date2  timeIntervalSince1970];
    interval1 -= interval2;
    if (interval1 < 0) {
        interval1 *= -1;
    }
    return interval1;
}

#pragma mark ----AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    //    [self next:nil];
    [_playButton updateProgressWithNumber:0];
    [_playButton setImagePic:[UIImage imageNamed:@"smart_nav"] centerCircle:NO];
    [self removeUITimer];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSNotificationNameStopPlay" object:nil];
    //TODO:关闭锁屏页面
}

/**
 *  当电话给过来时，进行相应的操作
 *  用户优先级>Unity优先级>系统优先级
 *
 */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    [self audioPlayerInterruptionOfSystem:NO];
}
/**
 *  打断结束，做相应的操作
 *
 */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
    [self audioPlayerInterruptionOfSystem:YES];
}

- (void)audioPlayerInterruptionOfSystem:(BOOL)play {
    [iConsole log:@"audioPlayerInterruptionOfSystem %d, user inter %d, unity inter %d, inter %d", play, self.isInterruptionByUser, self.isInterruptionByUnity, self.isInterruption];
    if (play) {
        if (!self.isInterruptionByUser && !self.isInterruptionByUnity && self.isInterruption) {
            [self playOrPause:YES];
        }
        self.isInterruption = NO;
    } else {
        [self playOrPause:NO];
        self.isInterruption = YES;
    }
}

- (void)audioPlayerInterruptionOfUser:(BOOL)play {
    [iConsole log:@"audioPlayerInterruptionOfUser %d, user inter %d", play, self.isInterruptionByUser];
    if (play) {
        [self playOrPause:YES];
        self.isInterruptionByUser = NO;
    } else {
        self.isInterruptionByUser = YES;
        [self playOrPause:NO];
    }
}

/**
 *  当Unity打断时，进行相应的操作,play表示Unity控制原生的播放
 *
 */
- (void)audioPlayerInterruptionOfUnity:(BOOL)play {
    [iConsole log:@"audioPlayerInterruptionOfUnity %d, user inter %d, unity inter %d", play, self.isInterruptionByUser, self.isInterruptionByUnity];
    //继续播放
    if (play) {
        if (!self.isInterruptionByUser && self.isInterruptionByUnity) {
            [self playOrPause:YES];
        }
        self.isInterruptionByUnity = NO;
    }
    //暂停
    else {
        [self playOrPause:NO];
        self.isInterruptionByUnity = YES;
    }
}

#pragma mark ----音乐控制
//重置播放的歌曲
- (void)resetPlayingMusic {
    [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.name];
    [self removeUITimer];
    [self.player stop];
    self.player = nil;
    _playingMusic = nil;
}

/**
 *  切换播放或者暂停
 *
 */
- (IBAction)playOrPause:(BOOL)play {
    if (_player) {
        if (play && !_player.isPlaying) {
            [_player play];
            [self addUITimer];
        } else if (!play && _player.isPlaying) {
            [_player pause];
            [self removeUITimer];
        } else {
            NSLog(@"playOrPause other play:%d， isPlaying:%d", play, _player.isPlaying);
        }
    }
}

- (void)setNavOpen:(BOOL)navOpen {
    if (navOpen) {
        _firstNavOpen = YES;
    }
    _navOpen = navOpen;
}

- (NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
    // UIInterfaceOrientationMaskAll
    // it is the safest way of doing it:
    // - GameCenter and some other services might have portrait-only variant
    //     and will throw exception if portrait is not supported here
    // - When you change allowed orientations if you end up forbidding current one
    //     exception will be thrown
    // Anyway this is intersected with values provided from UIViewController, so we are good
    return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown)
    | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationLandscapeLeft);
}

@end
