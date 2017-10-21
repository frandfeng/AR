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
#import "LocationManager.h"
#import "ZYMusic.h"
#import "ZYMusicTool.h"
#import "ZYAudioManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <notify.h>
#import "ZYLrcLine.h"
#import "ZYPlayingViewController.h"
#import "PWApplicationUtils.h"

@interface AppDelegate () <AVAudioPlayerDelegate>

//正在播放的音频
@property (nonatomic, strong) ZYMusic *playingMusic;
//音频播放器
@property (nonatomic, strong) AVAudioPlayer *player;
//判断歌曲播放过程中是否被电话等打断播放
@property (nonatomic, assign) BOOL isInterruption;

//定位的定时器
@property (nonatomic, strong) NSTimer *locTimer;
@property (nonatomic, strong) CLLocation *currentLocation;

//更新UI的定时器
@property (nonatomic, strong) NSTimer *uiTimer;

//锁屏图片视图,用来绘制带歌词的image
@property (nonatomic, strong) UIImageView *lrcImageView;
//最后一次锁屏之后的歌词海报
@property (nonatomic, strong) UIImage *lastImage;
//用来显示锁屏歌词
@property (nonatomic, strong) UITextView *lockScreenTableView;

@end

@implementation AppDelegate
- (UIWindow*)unityWindow {
    return self.unityController.window;
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
    [self addLocTimer];
    [self createRemoteCommandCenter];
    _player = [[AVAudioPlayer alloc] init];
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
    ZYPlayingViewController *vc = [[ZYPlayingViewController alloc] init];
    vc.player = _player;
    [[PWApplicationUtils sharedInstance].activityViewController presentViewController:vc animated:YES completion:nil];
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

#pragma mark ---定位定时器
- (void)addLocTimer {
    //在新增定时器之前，先移除之前的定时器
    [self removeLocTimer];
    [self loc];
    self.locTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(loc) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.locTimer forMode:NSRunLoopCommonModes];
}
- (void)removeLocTimer {
    [self.locTimer invalidate];
    self.locTimer = nil;
}

- (void)loc {
    LocationManager *locManager = [LocationManager sharedLocationManager];
    __weak __typeof__(LocationManager *) weakLocManager = locManager;
    __weak __typeof__(self) weakSelf = self;
    
    [iConsole info:@"开始请求位置信息。。。"];
    [locManager startLocation:^(NSArray<CLLocation *> *locations) {
        if (locations!=nil&&locations.count>0) {
            weakSelf.currentLocation = [locations firstObject];
            [iConsole info:@"获取到地理位置 %lf, %lf", weakSelf.currentLocation.coordinate.latitude, weakSelf.currentLocation.coordinate.longitude];
            int index = [self getIndexOfMusicForLocation:_currentLocation];
            if (index >= 0) {
                ZYMusic *music = [ZYMusicTool musics][index];
                [ZYMusicTool setPlayingMusic:music];
                [self removeUITimer];
                [self startPlayingMusic];
            }
        }
    }];
}

- (int)getIndexOfMusicForLocation:(CLLocation *)location {
    int index = -1;
    int distance = 10000000;
    for (int i=0; i<[ZYMusicTool musics].count; i++) {
        ZYMusic *music = [ZYMusicTool musics][i];
        NSArray *array = [music.location componentsSeparatedByString:@","];
        if (array!=nil && array.count>1) {
            CLLocation *placeLoc = [[CLLocation alloc] initWithLatitude:[array[1] doubleValue]  longitude:[array[0] doubleValue]];
            int distanceTemp = [self distanceFromLocation:placeLoc andLoctaion:location];
            if (distanceTemp<distance) {
                distance = distanceTemp;
                index = i;
            }
        }
    }
    ZYMusic *music = nil;
    if (index>=0 && distance<30) {
        music = [ZYMusicTool musics][index];
        [iConsole log:@"离我 30m 以内最近的景点是'%@', 距离为 %d m", music.name, distance];
    } else if (index>=0) {
        music = [ZYMusicTool musics][index];
        index = -1;
        [iConsole log:@"离我最近的景点是'%@', 距离为%dm", music.name, distance];
    } else {
        [iConsole log:@"没有找到附近的景点信息"];
    }
    return index;
}

- (CLLocationDistance)distanceFromLocation:(CLLocation *)firstLocation andLoctaion:(CLLocation *)secondLocation {
    CLLocationDistance meters= [firstLocation distanceFromLocation:secondLocation];
    return meters;
}

//锁屏界面开启和监控远程控制事件
- (void)createRemoteCommandCenter {
    //远程控制命令中心 iOS 7.1 之后  详情看官方文档：https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player play];
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

//开始播放音乐
- (void)startPlayingMusic
{
    if (self.playingMusic == [ZYMusicTool playingMusic])  {
        [iConsole log:@"相同的景点，不需要播放新音频"];
        return;
    }
    [iConsole log:@"开始播放新音频"];
    
    // 设置所需要的数据
    self.playingMusic = [ZYMusicTool playingMusic];
//    self.iconView.image = [UIImage imageNamed:@"yiheyuan"];
//    self.songLabel.text = self.playingMusic.name;
    
    //开发播放音乐
    self.player = [[ZYAudioManager defaultManager] playingMusic:self.playingMusic.musicId];
    self.player.delegate = self;
    
//    self.timeLabel.text = [self stringWithTime:self.player.duration];
    
    [self addUITimer];
    //切换歌词
    //    self.lrcView.fileName = self.playingMusic.lrcname;
//    self.playOrPauseButton.selected = YES;
}

/**
 *  添加定时器，更新滑块进度，锁屏页面进度
 */
- (void)addUITimer
{
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
    
    [self.playButton setTitle:[NSString stringWithFormat:@"%d", (int)(temp*100)] forState:UIControlStateNormal];
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
- (void)showLockScreenTotaltime:(float)totalTime andCurrentTime:(float)currentTime andLyricsPoster:(BOOL)isShow{
    
    // 播放信息中心
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    
    // 初始化播放信息
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    // 专辑名称
    info[MPMediaItemPropertyAlbumTitle] = self.playingMusic.name;
    // 歌手
    info[MPMediaItemPropertyArtist] = self.playingMusic.musicId;
    // 歌曲名称
    info[MPMediaItemPropertyTitle] = [NSString stringWithFormat:@"%f,@%f", _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude];
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
        //        [_lrcImageView addSubview:self.lockScreenTableView];
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

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //    [self next:nil];
}
/**
 *  当电话给过来时，进行相应的操作
 *
 */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    if ([self.player isPlaying]) {
        [self playOrPause:NO];
        self.isInterruption = YES;
    }
}
/**
 *  打断结束，做相应的操作
 *
 */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    if (self.isInterruption) {
        self.isInterruption = NO;
        [self playOrPause:YES];
    }
}

/**
 *  播放或者暂停
 *
 */
- (IBAction)playOrPause:(BOOL)isPlay {
    if (isPlay) {
        [[ZYAudioManager defaultManager] playingMusic:self.playingMusic.musicId];
        [self addUITimer];
    } else {
        [[ZYAudioManager defaultManager] pauseMusic:self.playingMusic.musicId];
        [self removeUITimer];
    }
}

@end
