//
//  ZYPlayingViewController.m
//  ZYMusicPlayer
//
//  Created by 王志盼 on 15/10/13.
//  Copyright © 2015年 王志盼. All rights reserved.
//

#import "ZYPlayingViewController.h"
#import "UIView+Extension.h"
#import "ZYMusic.h"
#import <AVFoundation/AVFoundation.h>
#import "ZYMusicTool.h"
#import "ZYAudioManager.h"
#import "ZYLrcView.h"
#import "UIView+AutoLayout.h"
#import <MediaPlayer/MediaPlayer.h>
#import <notify.h>
#import "ZYLrcLine.h"
#import "AppDelegate.h"
#import "INTULocationManager.h"
#import "LocationManager.h"
#import "iConsole.h"

@interface ZYPlayingViewController ()  <AVAudioPlayerDelegate>

@property (nonatomic, strong) ZYMusic *playingMusic;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) CLLocation *currentLocation;

//显示播放进度条的定时器
@property (nonatomic, strong) NSTimer *timer;
//定位的定时器
@property (nonatomic, strong) NSTimer *locTimer;
//显示歌词的定时器
@property (nonatomic, strong) CADisplayLink *lrcTimer;
//判断歌曲播放过程中是否被电话等打断播放
@property (nonatomic, assign) BOOL isInterruption;
//歌词视图
@property (nonatomic, weak) ZYLrcView *lrcView;
//歌曲图片
@property (strong, nonatomic) IBOutlet UIImageView *iconView;
//歌曲名字
@property (strong, nonatomic) IBOutlet UILabel *songLabel;
//暂停\播放按钮
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
//整首歌是多长时间
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
//歌曲进度滑块
@property (weak, nonatomic) IBOutlet UISlider *sliderView;
//滑块上面显示当前时间的label
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
//上半部分视图view
@property (weak, nonatomic) IBOutlet UIView *bottomView;
//操作部分
@property (weak, nonatomic) IBOutlet UIView *topView;
//设置按钮
@property (weak, nonatomic) IBOutlet UIButton *lyricOrPhotoBtn;
//锁屏图片视图,用来绘制带歌词的image
@property (nonatomic, strong) UIImageView * lrcImageView;;
//用来显示锁屏歌词
@property (nonatomic, strong) UITextView * lockScreenTableView;


//设置按钮，暂控制显示图片还是歌词
- (IBAction)lyricOrPhoto:(id)sender;
//暂停或者播放
- (IBAction)playOrPause:(id)sender;
//退下窗口
- (IBAction)exit:(UIButton *)sender;
//拖动滑块时的处理
- (IBAction)sliderValueChanged:(id)sender;

@end

@implementation ZYPlayingViewController {
    id _playerTimeObserver;
    BOOL _isDragging;
    UIImage * _lastImage;//最后一次锁屏之后的歌词海报
    int _playingIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLrcView];
//    _playingIndex = 0;
//    ZYMusic *currentMusic = [ZYMusicTool musics][_playingIndex];
//    [ZYMusicTool setPlayingMusic:currentMusic];
//    [self startPlayingMusic];
    [self addLocTimer];
    [self createRemoteCommandCenter];
}

#pragma mark ----setup系列方法

- (void)setupLrcView
{
    ZYLrcView *lrcView = [[ZYLrcView alloc] init];
    self.lrcView = lrcView;
    lrcView.hidden = YES;
    [self.topView addSubview:lrcView];
    [lrcView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(50, 50, 100, 50)];
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

#pragma mark ----音乐控制
//重置播放的歌曲
- (void)resetPlayingMusic
{
    // 重置界面数据
    self.iconView.image = [UIImage imageNamed:@"default"];
    self.songLabel.text = nil;
    self.timeLabel.text = [self stringWithTime:0];
    self.sliderView.x = 0;
    
    //停止播放音乐
    [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.musicId];
    self.player = nil;
    
    //清空歌词
    self.lrcView.fileName = @"";
    self.lrcView.currentTime = 0;
    
    [self removeCurrentTimer];
    [self removeLrcTimer];
}

//开始播放音乐
- (void)startPlayingMusic
{
    if (self.playingMusic == [ZYMusicTool playingMusic])  {
        [self addCurrentTimer];
        [self addLrcTimer];
        return;
    }
    
    // 设置所需要的数据
    self.playingMusic = [ZYMusicTool playingMusic];
    self.iconView.image = [UIImage imageNamed:@"yiheyuan"];
    self.songLabel.text = self.playingMusic.name;
    
    //开发播放音乐
    self.player = [[ZYAudioManager defaultManager] playingMusic:self.playingMusic.musicId];
    self.player.delegate = self;
    
    self.timeLabel.text = [self stringWithTime:self.player.duration];
    
    [self addCurrentTimer];
    [self addLrcTimer];
    //切换歌词
//    self.lrcView.fileName = self.playingMusic.lrcname;
    self.playOrPauseButton.selected = YES;
}

#pragma mark ----进度条定时器处理
/**
 *  添加定时器，更新slider，播放进度和锁屏页面
 */
- (void)addCurrentTimer
{
    if (![self.player isPlaying]) return;
    
    //在新增定时器之前，先移除之前的定时器
    [self removeCurrentTimer];
    
    [self updateCurrentTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCurrentTimer) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

/**
 *  移除定时器
 */
- (void)removeCurrentTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

/**
 *  触发定时器
 */
- (void)updateCurrentTimer
{
    double temp = self.player.currentTime / self.player.duration;
    self.sliderView.value = temp;
//    self.slider.x = temp * (self.view.width - self.slider.width);
    
    float totalTime = self.player.duration;
    float currentTime = self.player.currentTime;
    
    self.timeLabel.text = [self stringWithTime:totalTime];
    self.progressLabel.text = [self stringWithTime:currentTime];
    
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
    }else if(screenLight){
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

#pragma mark ---定位定时器
- (void)addLocTimer {
    //在新增定时器之前，先移除之前的定时器
    [self removeLocTimer];
    [self loc];
    self.locTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(loc) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.locTimer forMode:NSRunLoopCommonModes];
}

- (void)loc {
    LocationManager *locManager = [LocationManager sharedLocationManager];
    __weak __typeof__(LocationManager *) weakLocManager = locManager;
    __weak __typeof__(self) weakSelf = self;
    
    [locManager startLocation:^(NSArray<CLLocation *> *locations) {
        if (locations!=nil&&locations.count>0) {
            weakSelf.currentLocation = [locations firstObject];
            [iConsole info:@"获取到地理位置 %@", weakSelf.currentLocation];
            int index = [self getIndexOfMusicForLocation:_currentLocation];
            if (index >= 0) {
//                [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.musicId];
//                [self resetPlayingMusic];
                ZYMusic *music = [ZYMusicTool musics][index];
                [ZYMusicTool setPlayingMusic:music];
                [self removeCurrentTimer];
                [self removeLrcTimer];
                [self startPlayingMusic];
            }
        }
    }];
}

- (void)loc1 {
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyHouse
                                       timeout:0.0
                          delayUntilAuthorized:YES    // This parameter is optional, defaults to NO if omitted
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             if (status == INTULocationStatusSuccess) {
                                                 // Request succeeded, meaning achievedAccuracy is at least the requested accuracy, and
                                                 // currentLocation contains the device's current location.
                                                 _currentLocation = currentLocation;
                                                 int index = [self getIndexOfMusicForLocation:_currentLocation];
                                                 if (index >= 0) {
                                                     [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.musicId];
                                                     [self resetPlayingMusic];
                                                     ZYMusic *music = [ZYMusicTool musics][index];
                                                     [ZYMusicTool setPlayingMusic:music];
                                                     [self removeCurrentTimer];
                                                     [self removeLrcTimer];
                                                     [self startPlayingMusic];
                                                 }
//                                                 [self next:nil];
                                             }
                                             else if (status == INTULocationStatusTimedOut) {
                                                 // Wasn't able to locate the user with the requested accuracy within the timeout interval.
                                                 // However, currentLocation contains the best location available (if any) as of right now,
                                                 // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
//                                                 _currentLocation = currentLocation;
//                                                 [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.musicId];
//                                                 [ZYMusicTool setPlayingMusic:[ZYMusicTool nextMusic]];
//                                                 [self removeCurrentTimer];
//                                                 [self removeLrcTimer];
//                                                 [self startPlayingMusic];
//                                                 [self next:nil];
                                                 [iConsole info:@"INTULocationStatusTimedOut"];
                                             }
                                             else {
                                                 // An error occurred, more info is available by looking at the specific status returned.
                                                 [iConsole info:@"requestLocationWithDesiredAccuracy else"];
                                             }
                                         }];
}

- (void)removeLocTimer {
    [self.locTimer invalidate];
    self.locTimer = nil;
}

#pragma mark ----歌词定时器，更新歌词

- (void)addLrcTimer
{
    if (self.lrcView.hidden == YES) return;
    
    if (self.player.isPlaying == NO && self.lrcTimer) {
        [self updateLrcTimer];
        return;
    }
    
    [self removeLrcTimer];
    
    [self updateLrcTimer];
    
    self.lrcTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLrcTimer)];
    [self.lrcTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)removeLrcTimer
{
    [self.lrcTimer invalidate];
    self.lrcTimer = nil;
}

- (void)updateLrcTimer
{
    self.lrcView.currentTime = self.player.currentTime;
}
#pragma mark ----私有方法
/**
 *  将时间转化为合适的字符串
 *
 */
- (NSString *)stringWithTime:(NSTimeInterval)time
{
    int minute = time / 60;
    int second = (int)time % 60;
    return [NSString stringWithFormat:@"%02d:%02d",minute, second];
}

- (int)getIndexOfMusicForLocation:(CLLocation *)location {
    for (int i=0; i<[ZYMusicTool musics].count; i++) {
        ZYMusic *music = [ZYMusicTool musics][i];
        NSArray *array = [music.location componentsSeparatedByString:@","];
        if (array!=nil && array.count>1) {
            CLLocation *placeLoc = [[CLLocation alloc] initWithLatitude:[array[1] doubleValue]  longitude:[array[0] doubleValue]];
            if ([self distanceFromLocation:placeLoc andLoctaion:location]<10) {
                [iConsole info:@"getIndexOfMusicForLocation %d", i];
                return i;
            }
        }
    }
    return -1;
}

- (CLLocationDistance)distanceFromLocation:(CLLocation *)firstLocation andLoctaion:(CLLocation *)secondLocation {
    [iConsole info:@"first location %@", firstLocation];
    [iConsole info:@"second location %@", secondLocation];
    CLLocationDistance meters= [firstLocation distanceFromLocation:secondLocation];
    [iConsole info:@"distance %lf", meters];
    return meters;
}

#pragma mark ----控件方法
/**
 *  显示歌词或者图片
 *
 */
- (IBAction)lyricOrPhoto:(UIButton *)sender {
    if (self.lrcView.isHidden) { // 显示歌词，盖住图片
        self.lrcView.hidden = NO;
        sender.selected = YES;
        
        [self addLrcTimer];
    } else { // 隐藏歌词，显示图片
        self.lrcView.hidden = YES;
        sender.selected = NO;
        
        [self removeLrcTimer];
    }
}

/**
 *  将控制器退下
 *
 */
- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
//        [(AppDelegate *)[UIApplication sharedApplication].delegate hideUnityWindow];
    }];
}

- (IBAction)sliderValueChanged:(id)sender {
    UISlider *slider = (id)sender;
    CGFloat time = slider.value * self.player.duration;
    [self.progressLabel setText:[self stringWithTime:time]];
    
    self.player.currentTime = time;
    
    [self updateCurrentTimer];
    [self updateLrcTimer];
}

/**
 *  播放或者暂停
 *
 */
- (IBAction)playOrPause:(id)sender {
    if (self.playOrPauseButton.isSelected == NO) {
        self.playOrPauseButton.selected = YES;
        [[ZYAudioManager defaultManager] playingMusic:self.playingMusic.musicId];
        [self addCurrentTimer];
        [self addLrcTimer];
    }
    else{
        self.playOrPauseButton.selected = NO;
        [[ZYAudioManager defaultManager] pauseMusic:self.playingMusic.musicId];
        [self removeCurrentTimer];
        [self removeLrcTimer];
    }
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
        [self playOrPause:nil];
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
        [self playOrPause:nil];
    }
}

@end
