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

//显示播放进度条的定时器
@property (nonatomic, strong) NSTimer *uiTimer;
//判断歌曲播放过程中是否被电话等打断播放
@property (nonatomic, assign) BOOL isInterruption;
//歌曲图片
@property (strong, nonatomic) IBOutlet UIImageView *iconView;
//歌曲名字
@property (strong, nonatomic) IBOutlet UILabel *songLabel;
//暂停\播放按钮
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
//整首歌是多长时间
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
//滑块上面显示当前时间的label
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
//歌曲进度滑块
@property (weak, nonatomic) IBOutlet UISlider *sliderView;
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
    _playingMusic = [ZYMusicTool playingMusic];
    if (_playingMusic) {
        [self startPlayingMusic];
    }
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

//开始播放音乐
- (void)startPlayingMusic {
    // 设置所需要的数据
    self.playingMusic = [ZYMusicTool playingMusic];
    self.iconView.image = [UIImage imageNamed:@"yiheyuan"];
    self.songLabel.text = self.playingMusic.name;
    
    //开发播放音乐
//    self.player = [[ZYAudioManager defaultManager] playingMusic:self.playingMusic.musicId];
//    self.player.delegate = self;
    
    self.timeLabel.text = [self stringWithTime:self.player.duration];
    
    [self addUITimer];
    self.playOrPauseButton.selected = YES;
}

#pragma mark ----进度条定时器处理
/**
 *  添加定时器，更新slider，播放进度和锁屏页面
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
- (void)removeUITimer
{
    [self.uiTimer invalidate];
    self.uiTimer = nil;
}

/**
 *  触发定时器
 */
- (void)updateUI
{
    double temp = self.player.currentTime / self.player.duration;
    self.sliderView.value = temp;
//    self.slider.x = temp * (self.view.width - self.slider.width);
    
    float totalTime = self.player.duration;
    float currentTime = self.player.currentTime;
    
    self.timeLabel.text = [self stringWithTime:totalTime];
    self.progressLabel.text = [self stringWithTime:currentTime];
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
}

/**
 *  播放或者暂停
 *
 */
- (IBAction)playOrPause:(id)sender {
    if (self.playOrPauseButton.isSelected == NO) {
        self.playOrPauseButton.selected = YES;
        [[ZYAudioManager defaultManager] playingMusic:self.playingMusic.musicId];
        [self addUITimer];
    }
    else{
        self.playOrPauseButton.selected = NO;
        [[ZYAudioManager defaultManager] pauseMusic:self.playingMusic.musicId];
        [self removeUITimer];
    }
}

@end
