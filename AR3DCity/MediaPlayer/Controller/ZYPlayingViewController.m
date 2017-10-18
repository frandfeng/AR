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

@interface ZYPlayingViewController ()  <AVAudioPlayerDelegate>

@property (nonatomic, strong) ZYMusic *playingMusic;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) CLLocation *currentLocation;

/**
 *  显示播放进度条的定时器
 */
@property (nonatomic, strong) NSTimer *timer;

/**
 *  定位的定时器
 */
@property (nonatomic, strong) NSTimer *locTimer;
/**
 *  显示歌词的定时器
 */
@property (nonatomic, strong) CADisplayLink *lrcTimer;
/**
 *  判断歌曲播放过程中是否被电话等打断播放
 */
@property (nonatomic, assign) BOOL isInterruption;

@property (nonatomic, weak) ZYLrcView *lrcView;
/**
 *  歌手图片
 */
@property (strong, nonatomic) IBOutlet UIImageView *iconView;
/**
 *  歌曲名字
 */
@property (strong, nonatomic) IBOutlet UILabel *songLabel;
/**
 *  歌手名字
 */
@property (strong, nonatomic) IBOutlet UILabel *singerLabel;
/**
 *  暂停\播放按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
/**
 *  整首歌是多长时间
 */
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
/**
 *  歌曲进度颜色背景
 */
@property (weak, nonatomic) IBOutlet UIView *progressView;
/**
 *  歌曲滑块
 */
@property (weak, nonatomic) IBOutlet UIButton *slider;
/**
 *  滑块上面显示当前时间的label
 */
@property (weak, nonatomic) IBOutlet UIButton *showProgressLabel;

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UIButton *exitBtn;
@property (weak, nonatomic) IBOutlet UIButton *lyricOrPhotoBtn;



/**
 *  显示图片还是歌词
 *
 */
- (IBAction)lyricOrPhoto:(id)sender;
/**
 *  暂停或者播放
 *
 */
- (IBAction)playOrPause:(id)sender;
/**
 *  退下窗口
 *
 */
- (IBAction)exit:(UIButton *)sender;
/**
 *  拖拽滑块时，调用的方法
 *
 */
- (IBAction)panSlider:(UIPanGestureRecognizer *)sender;
/**
 *  点击背景时，滑块调整位置时调用的方法
 *
 */
- (IBAction)tapProgressView:(UITapGestureRecognizer *)sender;
- (IBAction)previous:(id)sender;
- (IBAction)next:(id)sender;

//锁屏图片视图,用来绘制带歌词的image
@property (nonatomic, strong) UIImageView * lrcImageView;;
//用来显示锁屏歌词
@property (nonatomic, strong) UITextView * lockScreenTableView;

@end

@implementation ZYPlayingViewController {
    id _playerTimeObserver;
    BOOL _isDragging;
    UIImage * _lastImage;//最后一次锁屏之后的歌词海报
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
    [self.slider setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.slider.font = [UIFont systemFontOfSize:12];
    [self setupLrcView];
//    [self playControl];
    [self createRemoteCommandCenter];
}

#pragma mark ----setup系列方法

- (void)setupLrcView
{
    ZYLrcView *lrcView = [[ZYLrcView alloc] init];
    self.lrcView = lrcView;
    lrcView.hidden = YES;
    [self.topView addSubview:lrcView];
    [lrcView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, - 50, 0)];
    [self.topView insertSubview:self.exitBtn aboveSubview:lrcView];
    [self.topView insertSubview:self.lyricOrPhotoBtn aboveSubview:lrcView];
}

//锁屏界面开启和监控远程控制事件
- (void)createRemoteCommandCenter{
    /**/
    //远程控制命令中心 iOS 7.1 之后  详情看官方文档：https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    //   MPFeedbackCommand对象反映了当前App所播放的反馈状态. MPRemoteCommandCenter对象提供feedback对象用于对媒体文件进行喜欢, 不喜欢, 标记的操作. 效果类似于网易云音乐锁屏时的效果
    
    //添加喜欢按钮
//    MPFeedbackCommand *likeCommand = commandCenter.likeCommand;
//    likeCommand.enabled = YES;
//    likeCommand.localizedTitle = @"喜欢";
//    [likeCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        NSLog(@"喜欢");
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//    //添加不喜欢按钮，假装是“上一首”
//    MPFeedbackCommand *dislikeCommand = commandCenter.dislikeCommand;
//    dislikeCommand.enabled = YES;
//    dislikeCommand.localizedTitle = @"上一首";
//    [dislikeCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        NSLog(@"上一首");
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//    //标记
//    MPFeedbackCommand *bookmarkCommand = commandCenter.bookmarkCommand;
//    bookmarkCommand.enabled = YES;
//    bookmarkCommand.localizedTitle = @"标记";
//    [bookmarkCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        NSLog(@"标记");
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
    
    //    commandCenter.togglePlayPauseCommand 耳机线控的暂停/播放
    
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    //        [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
    //            NSLog(@"上一首");
    //            return MPRemoteCommandHandlerStatusSuccess;
    //        }];
    
    [commandCenter.changePlaybackRateCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    //    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
    //        NSLog(@"下一首");
    //        return MPRemoteCommandHandlerStatusSuccess;
    //    }];
    
    //快进
    //    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipForwardCommand;
    //    skipBackwardIntervalCommand.preferredIntervals = @[@(54)];
    //    skipBackwardIntervalCommand.enabled = YES;
    //    [skipBackwardIntervalCommand addTarget:self action:@selector(skipBackwardEvent:)];
    
    //在控制台拖动进度条调节进度（仿QQ音乐的效果）
    [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        float totlaTime = self.player.duration;
        MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
//        [self.player seekToTime:CMTimeMake(totlaTime*playbackPositionEvent.positionTime/CMTimeGetSeconds(totlaTime), totlaTime.timescale) completionHandler:^(BOOL finished) {
//        }];
        self.player.currentTime = playbackPositionEvent.positionTime;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    
}

- (void)show
{
//    NSLog(@"%@",NSStringFromCGRect(self.view.frame));
    UIWindow *windows = [UIApplication sharedApplication].keyWindow;
    self.view.bounds = windows.bounds;
    [windows addSubview:self.view];
    self.view.y = self.view.height;
    self.view.hidden = NO;
    if (self.playingMusic != [ZYMusicTool playingMusic]) {
        [self resetPlayingMusic];
    }
    
    windows.userInteractionEnabled = NO;         //以免在动画过程中用户多次点击，或者造成其他事件的发生
    [UIView animateWithDuration:0.25 animations:^{
        self.view.y = 0;
    }completion:^(BOOL finished) {
        windows.userInteractionEnabled = YES;
        [self startPlayingMusic];
    }];
}

//- (void)playControl{
//
//    //后台播放音频设置,需要在Capabilities->Background Modes中勾选Audio,Airplay,and Picture in Picture
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setActive:YES error:nil];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
//
//    __weak ZYPlayingViewController * weakSelf = self;
//    _playerTimeObserver = [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMake(0.1*30, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
//
//        CGFloat currentTime = CMTimeGetSeconds(time);
//
//        CMTime total = weakSelf.player.currentItem.duration;
//        CGFloat totalTime = CMTimeGetSeconds(total);
//
//        if (!_isDragging) {
//
//            //歌词滚动显示
////            for ( int i = (int)(self.lrcArray.count - 1); i >= 0 ;i--) {
////                wslLrcEach * lrc = self.lrcArray[i];
////                if (lrc.time < currentTime) {
////                    self.currentRow = i;
////                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: self.currentRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
////                    [self.tableView reloadData];
////                    [self.lockScreenTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: self. currentRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
////                    [self.lockScreenTableView reloadData];
////                    break;
////                }
////            }
//
//        }
//
//
//        //监听锁屏状态 lock=1则为锁屏状态
//        uint64_t locked;
//        __block int token = 0;
//        notify_register_dispatch("com.apple.springboard.lockstate",&token,dispatch_get_main_queue(),^(int t){
//        });
//        notify_get_state(token, &locked);
//
//        //监听屏幕点亮状态 screenLight = 1则为变暗关闭状态
//        uint64_t screenLight;
//        __block int lightToken = 0;
//        notify_register_dispatch("com.apple.springboard.hasBlankedScreen",&lightToken,dispatch_get_main_queue(),^(int t){
//        });
//        notify_get_state(lightToken, &screenLight);
//
//        BOOL isShowLyricsPoster = NO;
//        // NSLog(@"screenLight=%llu locked=%llu",screenLight,locked);
//        if (screenLight == 0 && locked == 1) {
//            //点亮且锁屏时
//            isShowLyricsPoster = YES;
//        }else if(screenLight){
//            return;
//        }
//
//        //展示锁屏歌曲信息，上面监听屏幕锁屏和点亮状态的目的是为了提高效率
//        [self showLockScreenTotaltime:totalTime andCurrentTime:currentTime andLyricsPoster:isShowLyricsPoster];
//
//    }];
//
//    /* iOS 7.1之前
//     //让App开始接收远程控制事件, 该方法属于UIApplication类
//     [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//     //结束远程控制,需要的时候关闭
//     //     [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
//     //处理控制台的暂停/播放、上/下一首事件
//     [[NSNotificationCenter defaultCenter] addObserverForName:@"songRemoteControlNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
//
//     NSInteger  eventSubtype = [notification.userInfo[@"eventSubtype"] integerValue];
//     switch (eventSubtype) {
//     case UIEventSubtypeRemoteControlNextTrack:
//     NSLog(@"下一首");
//     break;
//     case UIEventSubtypeRemoteControlPreviousTrack:
//     NSLog(@"上一首");
//     break;
//     case  UIEventSubtypeRemoteControlPause:
//     [self.player pause];
//     break;
//     case  UIEventSubtypeRemoteControlPlay:
//     [self.player play];
//     break;
//     //耳机上的播放暂停
//     case  UIEventSubtypeRemoteControlTogglePlayPause:
//     NSLog(@"播放或暂停");
//     break;
//     //后退
//     case UIEventSubtypeRemoteControlBeginSeekingBackward:
//     break;
//     case UIEventSubtypeRemoteControlEndSeekingBackward:
//     NSLog(@"后退");
//     break;
//     //快进
//     case UIEventSubtypeRemoteControlBeginSeekingForward:
//     break;
//     case UIEventSubtypeRemoteControlEndSeekingForward:
//     NSLog(@"前进");
//     break;
//     default:
//     break;
//     }
//
//     }];
//     */
//
//}

//展示锁屏歌曲信息：图片、歌词、进度、演唱者
- (void)showLockScreenTotaltime:(float)totalTime andCurrentTime:(float)currentTime andLyricsPoster:(BOOL)isShow{
    
    
    
    //切换锁屏
//    [self updateLockedScreenMusic];
    
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
    
//    NSMutableDictionary * songDict = [[NSMutableDictionary alloc] init];
//    //设置歌曲题目
//    [songDict setObject:@"多幸运" forKey:MPMediaItemPropertyTitle];
//    //设置歌手名
//    [songDict setObject:@"韩安旭" forKey:MPMediaItemPropertyArtist];
//    //设置专辑名
//    [songDict setObject:@"专辑名" forKey:MPMediaItemPropertyAlbumTitle];
//    //设置歌曲时长
//    [songDict setObject:[NSNumber numberWithDouble:totalTime]  forKey:MPMediaItemPropertyPlaybackDuration];
//    //设置已经播放时长
//    [songDict setObject:[NSNumber numberWithDouble:currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    UIImage * lrcImage = [UIImage imageNamed:@"backgroundImage5.jpg"];
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
        [_lrcImageView addSubview:self.lockScreenTableView];
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
    //设置显示的海报图片
    info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:lrcImage];
    
    
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

#pragma mark ----音乐控制
//重置播放的歌曲
- (void)resetPlayingMusic
{
    // 重置界面数据
    self.iconView.image = [UIImage imageNamed:@"play_cover_pic_bg"];
    self.singerLabel.text = nil;
    self.songLabel.text = nil;
    self.timeLabel.text = [self stringWithTime:0];
    self.slider.x = 0;
    self.progressView.width = self.slider.center.x;
    [self.slider setTitle:[self stringWithTime:0] forState:UIControlStateNormal];
    
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
        [self addLocTimer];
        [self addCurrentTimer];
        [self addLrcTimer];
        return;
    }
    
    // 设置所需要的数据
    self.playingMusic = [ZYMusicTool playingMusic];
//    self.iconView.image = [UIImage imageNamed:self.playingMusic.icon];
    self.songLabel.text = self.playingMusic.name;
    self.singerLabel.text = self.playingMusic.musicId;
    
    //开发播放音乐
    self.player = [[ZYAudioManager defaultManager] playingMusic:self.playingMusic.musicId];
    self.player.delegate = self;
    
    self.timeLabel.text = [self stringWithTime:self.player.duration];
    
    [self addLocTimer];
    [self addCurrentTimer];
    [self addLrcTimer];
    //切换歌词
//    self.lrcView.fileName = self.playingMusic.lrcname;
    self.playOrPauseButton.selected = YES;
}

#pragma mark ----进度条定时器处理
/**
 *  添加定时器
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
    self.slider.x = temp * (self.view.width - self.slider.width);
    [self.slider setTitle:[self stringWithTime:self.player.currentTime] forState:UIControlStateNormal];
    self.progressView.width = self.slider.center.x;
    
    float totalTime = self.player.duration;
    float currentTime = self.player.currentTime;
    
    if (!_isDragging) {
        
        //歌词滚动显示
        //            for ( int i = (int)(self.lrcArray.count - 1); i >= 0 ;i--) {
        //                wslLrcEach * lrc = self.lrcArray[i];
        //                if (lrc.time < currentTime) {
        //                    self.currentRow = i;
        //                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: self.currentRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        //                    [self.tableView reloadData];
        //                    [self.lockScreenTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: self. currentRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        //                    [self.lockScreenTableView reloadData];
        //                    break;
        //                }
        //            }
        
    }
    
    
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

#pragma mark ---定位定时器
- (void)addLocTimer {
    if (![self.player isPlaying]) return;
    
    //在新增定时器之前，先移除之前的定时器
    [self removeLocTimer];
    self.locTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(loc) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.locTimer forMode:NSRunLoopCommonModes];
}

- (void)loc {
//    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
//    [locMgr subscribeToLocationUpdatesWithDesiredAccuracy:INTULocationAccuracyHouse
//                                                    block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
//                                                        if (status == INTULocationStatusSuccess) {
//                                                            _currentLocation = currentLocation;
//                                                            [self next:nil];
//                                                            // A new updated location is available in currentLocation, and achievedAccuracy indicates how accurate this particular location is.
//                                                        }
//                                                        else {
//                                                            // An error occurred, more info is available by looking at the specific status returned. The subscription has been kept alive.
//                                                        }
//                                                    }];
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyBlock
                                       timeout:30.0
                          delayUntilAuthorized:YES    // This parameter is optional, defaults to NO if omitted
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             if (status == INTULocationStatusSuccess) {
                                                 // Request succeeded, meaning achievedAccuracy is at least the requested accuracy, and
                                                 // currentLocation contains the device's current location.
                                                 _currentLocation = currentLocation;
                                                 [self next:nil];
                                             }
                                             else if (status == INTULocationStatusTimedOut) {
                                                 // Wasn't able to locate the user with the requested accuracy within the timeout interval.
                                                 // However, currentLocation contains the best location available (if any) as of right now,
                                                 // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
                                                 _currentLocation = currentLocation;
                                                 [self next:nil];
                                             }
                                             else {
                                                 // An error occurred, more info is available by looking at the specific status returned.
                                             }
                                         }];
}

- (void)removeLocTimer {
    [self.locTimer invalidate];
    self.locTimer = nil;
}

#pragma mark ----歌词定时器

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
    
//    UIWindow *windows = [UIApplication sharedApplication].keyWindow;
//    windows.userInteractionEnabled = NO;
//
//    [UIView animateWithDuration:0.25 animations:^{
//        self.view.y = self.view.height;
//    }completion:^(BOOL finished) {
//        self.view.hidden = YES;            //view看不到了，将之隐藏掉，可以减少性能的消耗
//        [self removeCurrentTimer];
//        [self removeLrcTimer];
//        windows.userInteractionEnabled = YES;
//    }];
    [self dismissViewControllerAnimated:YES completion:^{
        [(AppDelegate *)[UIApplication sharedApplication].delegate hideUnityWindow];
    }];
}

/**
 *  拖动滑块，要做的事情
 *
 */
- (IBAction)panSlider:(UIPanGestureRecognizer *)sender {
    //得到挪动距离
    CGPoint point = [sender translationInView:sender.view];
    //将translation清空，免得重复叠加
    [sender setTranslation:CGPointZero inView:sender.view];

    CGFloat maxX = self.view.width - sender.view.width;
    sender.view.x += point.x;
    
    if (sender.view.x < 0) {
        sender.view.x = 0;
    }
    else if (sender.view.x > maxX){
        sender.view.x = maxX;
    }
    CGFloat time = (sender.view.x / (self.view.width - sender.view.width)) * self.player.duration;
    [self.showProgressLabel setTitle:[self stringWithTime:time] forState:UIControlStateNormal];
    [self.slider setTitle:[self stringWithTime:time] forState:UIControlStateNormal];
    self.progressView.width = sender.view.center.x;
    self.showProgressLabel.x = self.slider.x;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self removeCurrentTimer];
        [self removeLrcTimer];
        self.showProgressLabel.hidden = NO;
        self.showProgressLabel.y = self.showProgressLabel.superview.height - 15 - self.showProgressLabel.height;
    }
    else if (sender.state == UIGestureRecognizerStateEnded)
    {
        self.player.currentTime = time ;
        [self addLocTimer];
        [self addCurrentTimer];
        [self addLrcTimer];
        self.showProgressLabel.hidden = YES;
    }
}

/**
 *  轻击progressView，使得滑块走到对应位置
 *
 */
- (IBAction)tapProgressView:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:sender.view];
    
    self.player.currentTime = (point.x / sender.view.width) * self.player.duration;
    
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
        [self addLocTimer];
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
/**
 *  前一首
 *
 */
- (IBAction)previous:(id)sender {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.userInteractionEnabled = NO;
    [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.musicId];
    [ZYMusicTool setPlayingMusic:[ZYMusicTool previousMusic]];
    [self removeCurrentTimer];
    [self removeLrcTimer];
    [self startPlayingMusic];
    window.userInteractionEnabled = YES;
}
/**
 *  下一首
 *
 */
- (IBAction)next:(id)sender {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.userInteractionEnabled = NO;
    [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.musicId];
    [ZYMusicTool setPlayingMusic:[ZYMusicTool nextMusic]];
    [self removeCurrentTimer];
    [self removeLrcTimer];
    [self startPlayingMusic];
    window.userInteractionEnabled = YES;
}

#pragma mark ----AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self next:nil];
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

#pragma mark ----锁屏时候的设置，效果需要在真机上才可以看到
- (void)updateLockedScreenMusic
{
    
}

#pragma mark - 远程控制事件监听
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    //    event.type; // 事件类型
    //    event.subtype; // 事件的子类型
    //    UIEventSubtypeRemoteControlPlay                 = 100,
    //    UIEventSubtypeRemoteControlPause                = 101,
    //    UIEventSubtypeRemoteControlStop                 = 102,
    //    UIEventSubtypeRemoteControlTogglePlayPause      = 103,
    //    UIEventSubtypeRemoteControlNextTrack            = 104,
    //    UIEventSubtypeRemoteControlPreviousTrack        = 105,
    //    UIEventSubtypeRemoteControlBeginSeekingBackward = 106,
    //    UIEventSubtypeRemoteControlEndSeekingBackward   = 107,
    //    UIEventSubtypeRemoteControlBeginSeekingForward  = 108,
    //    UIEventSubtypeRemoteControlEndSeekingForward    = 109,
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
        case UIEventSubtypeRemoteControlPause:
            [self playOrPause:nil];
            break;
            
        case UIEventSubtypeRemoteControlNextTrack:
            [self next:nil];
            break;
            
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self previous:nil];
            
        default:
            break;
    }
}

@end
