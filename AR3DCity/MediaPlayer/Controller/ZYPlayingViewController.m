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
#import "ZYLrcView.h"
#import "UIView+AutoLayout.h"
#import "ZYLrcLine.h"
#import "AppDelegate.h"
#import "INTULocationManager.h"
#import "iConsole.h"

@interface ZYPlayingViewController ()  <AVAudioPlayerDelegate>

@property (nonatomic, strong) ZYMusic *playingMusic;
//显示歌词的定时器
@property (nonatomic, strong) CADisplayLink *lrcTimer;
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
    int _playingIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self setupLrcView];
//    _playingIndex = 0;
//    ZYMusic *currentMusic = [ZYMusicTool musics][_playingIndex];
//    [ZYMusicTool setPlayingMusic:currentMusic];
//    [self startPlayingMusic];
}

#pragma mark ----setup系列方法

//- (void)setupLrcView
//{
//    ZYLrcView *lrcView = [[ZYLrcView alloc] init];
//    self.lrcView = lrcView;
//    lrcView.hidden = YES;
//    [self.topView addSubview:lrcView];
//    [lrcView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(50, 50, 100, 50)];
//}
//
//#pragma mark ----音乐控制
////重置播放的歌曲
//- (void)resetPlayingMusic
//{
//    // 重置界面数据
//    self.iconView.image = [UIImage imageNamed:@"default"];
//    self.songLabel.text = nil;
//    self.timeLabel.text = [self stringWithTime:0];
//    self.sliderView.x = 0;
//
//    //停止播放音乐
//    [[ZYAudioManager defaultManager] stopMusic:self.playingMusic.musicId];
//    self.player = nil;
//
//    //清空歌词
//    self.lrcView.fileName = @"";
//    self.lrcView.currentTime = 0;
//
//    [self removeCurrentTimer];
//    [self removeLrcTimer];
//}



#pragma mark ----进度条定时器处理







#pragma mark ----歌词定时器，更新歌词

//- (void)addLrcTimer
//{
//    if (self.lrcView.hidden == YES) return;
//
//    if (self.player.isPlaying == NO && self.lrcTimer) {
//        [self updateLrcTimer];
//        return;
//    }
//
//    [self removeLrcTimer];
//
//    [self updateLrcTimer];
//
//    self.lrcTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLrcTimer)];
//    [self.lrcTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//}
//
//- (void)removeLrcTimer
//{
//    [self.lrcTimer invalidate];
//    self.lrcTimer = nil;
//}
//
//- (void)updateLrcTimer
//{
//    self.lrcView.currentTime = self.player.currentTime;
//}
//#pragma mark ----私有方法
///**
// *  将时间转化为合适的字符串
// *
// */
//- (NSString *)stringWithTime:(NSTimeInterval)time
//{
//    int minute = time / 60;
//    int second = (int)time % 60;
//    return [NSString stringWithFormat:@"%02d:%02d",minute, second];
//}
//
//
//#pragma mark ----控件方法
///**
// *  显示歌词或者图片
// *
// */
//- (IBAction)lyricOrPhoto:(UIButton *)sender {
//    if (self.lrcView.isHidden) { // 显示歌词，盖住图片
//        self.lrcView.hidden = NO;
//        sender.selected = YES;
//
//        [self addLrcTimer];
//    } else { // 隐藏歌词，显示图片
//        self.lrcView.hidden = YES;
//        sender.selected = NO;
//
//        [self removeLrcTimer];
//    }
//}
//
///**
// *  将控制器退下
// *
// */
//- (IBAction)exit:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:^{
////        [(AppDelegate *)[UIApplication sharedApplication].delegate hideUnityWindow];
//    }];
//}
//
//- (IBAction)sliderValueChanged:(id)sender {
//    UISlider *slider = (id)sender;
//    CGFloat time = slider.value * self.player.duration;
//    [self.progressLabel setText:[self stringWithTime:time]];
//
//    self.player.currentTime = time;
//
//    [self updateCurrentTimer];
//    [self updateLrcTimer];
//}




@end
