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
#import "LocationManager.h"
#import "iConsole.h"
#import "JCTiledScrollView.h"
#import "JCTiledView.h"
#import "ARAnnotation.h"
#import "ARAnnotationView.h"
#import "PWUnityMsgManager.h"
#import "PWApplicationUtils.h"

@interface ZYPlayingViewController ()  <AVAudioPlayerDelegate, JCTileSource, JCTiledScrollViewDelegate>

//显示播放进度条的定时器
@property (nonatomic, strong) NSTimer *uiTimer;
//判断歌曲播放过程中是否被电话等打断播放
@property (nonatomic, assign) BOOL isInterruption;
//歌曲图片
@property (strong, nonatomic) JCTiledScrollView *mapScrollView;
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
@property (nonatomic, strong) UIImageView * lrcImageView;
//用来显示锁屏歌词
@property (nonatomic, strong) UITextView * lockScreenTableView;
@property (nonatomic, strong) NSMutableArray * annotations;
@property (nonatomic, strong) ARAnnotation * currentLocAnnotation;

@property (nonatomic, assign) CGSize contentSize;


//设置按钮，暂控制显示图片还是歌词
- (IBAction)lyricOrPhoto:(id)sender;
//暂停或者播放
- (IBAction)playOrPause:(id)sender;
//退下窗口
- (IBAction)exit:(UIButton *)sender;
//拖动滑块时的处理
- (IBAction)sliderValueChanged:(id)sender;

@end

static NSString * const imagePicName = @"zhinengdaoyouditu.jpg";
static int const displayScale = 2;

@implementation ZYPlayingViewController {
    id _playerTimeObserver;
    BOOL _isDragging;
    UIImage * _lastImage;//最后一次锁屏之后的歌词海报
    int _playingIndex;
    
    CLLocation *leftTopLoc;
    CLLocation *leftBottomLoc;
    CLLocation *rightTopLoc;
    CLLocation *rightBottomLoc;
    int mapWidth;
    int mapHeight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDatas];
    [self addMapScrollView];
    [self refreshMusicUI];
    [self setCoordinate];
    [self addAnnotations];
    
    [((AppDelegate *)[UIApplication sharedApplication].delegate) hideButton:NO];
    [[PWUnityMsgManager sharedInstance] sendMsg2UnityOfType:@"OnIntelligentState" andValue:@"{\"params\":{\"isOpen\":\"true\"}}"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) bringButtonToFront:NO];
}

- (void)initDatas {
    UIImage *image = [UIImage imageNamed:imagePicName];
    _contentSize = CGSizeMake(image.size.width/[UIScreen mainScreen].scale/displayScale, image.size.height/[UIScreen mainScreen].scale/displayScale);
    mapWidth = image.size.width;
    mapHeight = image.size.height;
    _annotations = [NSMutableArray array];
}

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(location:) name:@"NSNotificationNameLocation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startPlay:) name:@"NSNotificationNameStartPlay" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlay:) name:@"NSNotificationNameStopPlay" object:nil];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSNotificationNameLocation" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSNotificationNameStartPlay" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSNotificationNameStopPlay" object:nil];
}

- (void)dealloc {
    [self removeNotifications];
    [[PWUnityMsgManager sharedInstance] sendMsg2UnityOfType:@"OnIntelligentState" andValue:@"{\"params\":{\"isOpen\":\"false\"}}"];
}

- (void)location:(NSNotification *)noti {
    NSLog(@"%@ === %@ === %@", noti.object, noti.userInfo, noti.name);
    CLBeacon *beacon = noti.object;
    if (_currentLocAnnotation) {
        [_mapScrollView removeAnnotation:_currentLocAnnotation];
        NSLog(@"remove current location x %lf, y %lf", _currentLocAnnotation.contentPosition.x, _currentLocAnnotation.contentPosition.y);
    }
    _currentLocAnnotation = [self getAnnotationByBeacon:beacon];
    _currentLocAnnotation.index = -1;
    [_mapScrollView addAnnotation:_currentLocAnnotation];
    [self removeAnnotations];
    [self addAnnotations];
    NSLog(@"add current location x %lf, y %lf", _currentLocAnnotation.contentPosition.x, _currentLocAnnotation.contentPosition.y);
//    [_mapScrollView refreshAnnotations];
}

- (void)startPlay:(NSNotification *)noti {
    [self refreshMusicUI];
    [_mapScrollView refreshAnnotations];
}

- (void)stopPlay:(NSNotification *)noti {
    [self removeUITimer];
    [_mapScrollView refreshAnnotations];
}

- (void)addMapScrollView {
    JCTiledScrollView *scrollView = [[JCTiledScrollView alloc] initWithFrame:self.view.frame contentSize:_contentSize];
    _mapScrollView = scrollView;
    [self.topView insertSubview:_mapScrollView atIndex:0];
    NSDictionary *viewsDictionary = @{@"mapScrollView":_mapScrollView};
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mapScrollView]|" options:0 metrics:nil views:viewsDictionary]];
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mapScrollView]|" options:0 metrics:nil views:viewsDictionary]];
    
    _mapScrollView.translatesAutoresizingMaskIntoConstraints = false;
    _mapScrollView.dataSource = self;
    _mapScrollView.tiledScrollViewDelegate = self;
    _mapScrollView.zoomScale = 1;
    
    _mapScrollView.tiledView.shouldAnnotateRect = true;
    //最大缩放比例
    _mapScrollView.levelsOfZoom = 2;
    _mapScrollView.levelsOfDetail = 2;
}

- (void)setCoordinate {
    //暂时设置办公室四个角
//    leftBottomLoc = [[CLLocation alloc] initWithLatitude:30.554578 longitude:104.056323];
//    rightBottomLoc = [[CLLocation alloc] initWithLatitude:30.554578 longitude:104.057339];
//    rightTopLoc = [[CLLocation alloc] initWithLatitude:30.555339 longitude:104.057339];
//    leftTopLoc = [[CLLocation alloc] initWithLatitude:30.555339 longitude:104.056323];
}

- (void)removeAnnotations {
    for (int i=0; i<_annotations.count; i++) {
        ARAnnotation *annotation = _annotations[i];
        [_mapScrollView removeAnnotation:annotation];
    }
}

- (void)addAnnotations {
    NSArray *musics = [ZYMusicTool musics];
    for (int i=0; i<musics.count; i++) {
        ZYMusic *music = musics[i];
        NSArray *array = [music.location componentsSeparatedByString:@","];
        if (array!=nil && array.count>1) {
            ARAnnotation *annotation = [self getAnnotationByMusic:music];
            annotation.index = i;
            [_annotations addObject:annotation];
            [_mapScrollView addAnnotation:annotation];
            NSLog(@"add annotations x %lf, y %lf", annotation.contentPosition.x, annotation.contentPosition.y);
        }
    }
}

//- (ARAnnotation *)getAnnotationByLocation:(CLLocation *)placeLoc {
//    CGFloat y = mapHeight / displayScale / [UIScreen mainScreen].scale * (placeLoc.coordinate.latitude-rightBottomLoc.coordinate.latitude)/(rightTopLoc.coordinate.latitude-rightBottomLoc.coordinate.latitude);
//    CGFloat x = mapWidth / displayScale / [UIScreen mainScreen].scale * (placeLoc.coordinate.longitude-rightBottomLoc.coordinate.longitude)/(leftBottomLoc.coordinate.longitude-rightBottomLoc.coordinate.longitude);
//    ARAnnotation *annotation = [[ARAnnotation alloc] init];
//    annotation.contentPosition = CGPointMake(x, y);
//    return annotation;
//}
                                        
- (ARAnnotation *)getAnnotationByMusic:(ZYMusic *)music {
    NSArray *array = [music.location componentsSeparatedByString:@","];
    if (array!=nil && array.count>1) {
//        CGFloat y = (mapHeight / displayScale / [UIScreen mainScreen].scale) * [array[1] intValue];
//        CGFloat x = mapWidth / displayScale / [UIScreen mainScreen].scale * [array[0] intValue];
        ARAnnotation *annotation = [[ARAnnotation alloc] init];
        annotation.contentPosition = CGPointMake([array[0] floatValue]/ displayScale / [UIScreen mainScreen].scale, [array[1] floatValue] / displayScale / [UIScreen mainScreen].scale);
        return annotation;
    }
    return nil;
}

- (ARAnnotation *)getAnnotationByBeacon:(CLBeacon *)beacon {
    int index = [PWApplicationUtils getIndexOfMusicForBeacon:beacon];
    ZYMusic *music = [ZYMusicTool musics][index];
    ARAnnotation *annotation = [self getAnnotationByMusic:music];
    annotation.contentPosition = CGPointMake(annotation.contentPosition.x, annotation.contentPosition.y+20);
    return annotation;
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
- (void)refreshMusicUI {
    // 设置所需要的数据
    ZYMusic *playingMusic = [ZYMusicTool playingMusic];
    AVAudioPlayer *player = [[ZYAudioManager defaultManager] player:playingMusic.musicId];;
    if (playingMusic) {
        self.songLabel.text = [NSString stringWithFormat:@"正在播放：%@", playingMusic.name];
        if (player) {
            self.timeLabel.text = [self stringWithTime:player.duration];
            if (player.isPlaying) {
                [self removeUITimer];
                [self addUITimer];
                self.playOrPauseButton.selected = YES;
            } else {
                double temp = player.currentTime / player.duration;
                self.sliderView.value = temp;
                float currentTime = player.currentTime;
                self.progressLabel.text = [self stringWithTime:currentTime];
                self.playOrPauseButton.selected = NO;
            }
        } else {
            NSAssert(YES, @"_playingMusic not null but player null");
        }
    } else {
        self.sliderView.value = 0;
        self.progressLabel.text =  @"00:00";
        self.timeLabel.text = @"00:00";
        self.songLabel.text = @"";
        self.playOrPauseButton.selected = NO;
    }
}

#pragma mark ----进度条定时器处理
/**
 *  添加定时器，更新slider，播放进度和锁屏页面
 */
- (void)addUITimer {
    ZYMusic *playingMusic = [ZYMusicTool playingMusic];
    AVAudioPlayer *player = [[ZYAudioManager defaultManager] player:playingMusic.musicId];
    if (![player isPlaying]) return;
    
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
    ZYMusic *playingMusic = [ZYMusicTool playingMusic];
    AVAudioPlayer *player = [[ZYAudioManager defaultManager] player:playingMusic.musicId];
    double temp = player.currentTime / player.duration;
    self.sliderView.value = temp;
    
    float currentTime = player.currentTime;
    
    self.progressLabel.text = [self stringWithTime:currentTime];
}

#pragma mark ----私有方法
/**
 *  将时间转化为合适的字符串
 *
 */
- (NSString *)stringWithTime:(NSTimeInterval)time {
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
    ZYMusic *playingMusic = [ZYMusicTool playingMusic];
    AVAudioPlayer *player = [[ZYAudioManager defaultManager] player:playingMusic.musicId];
    CGFloat time = slider.value * player.duration;
    [self.progressLabel setText:[self stringWithTime:time]];
    
    player.currentTime = time;
}

/**
 *  播放或者暂停
 *
 */
- (IBAction)playOrPause:(id)sender {
    ZYMusic *playingMusic = [ZYMusicTool playingMusic];
    AVAudioPlayer *player = [[ZYAudioManager defaultManager] player:playingMusic.musicId];
    if (player) {
        if (self.playOrPauseButton.isSelected == NO) {
            self.playOrPauseButton.selected = YES;
            ((AppDelegate *)[UIApplication sharedApplication].delegate).isInterruptionByUser = NO;
            [player play];
            [self addUITimer];
        } else {
            self.playOrPauseButton.selected = NO;
            ((AppDelegate *)[UIApplication sharedApplication].delegate).isInterruptionByUser = YES;
            [player pause];
            [self removeUITimer];
        }
    }
}

- (void)resetPlayingMusic {
    ZYMusic *playingMusic = [ZYMusicTool playingMusic];
    AVAudioPlayer *player = [[ZYAudioManager defaultManager] player:playingMusic.musicId];
    [player stop];
    NSLog(@"player stop %@", player);
    player = nil;
    playingMusic = nil;
}

  //MARK: TileSource
- (UIImage * _Nullable)tiledScrollView:(JCTiledScrollView * _Nonnull)scrollView imageForRow:(NSInteger)row column:(NSInteger)column scale:(NSInteger)scale {
    NSString *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    scale = displayScale * [UIScreen mainScreen].scale / scale;
    NSString *imageName = [NSString stringWithFormat:@"%@/yiheyuan-%02dx-%02d-%02d.png",filePath, scale, (int)row, (int)column];
    UIImage *image = [UIImage imageNamed:imageName];
    NSLog(@"imageName %@", imageName);
    if (!image) {
        NSLog(@"image null named %@", imageName);
    }
    return image;
}
  //MARK: JCTiledScrollViewDelegate
- (JCAnnotationView *)tiledScrollView:(JCTiledScrollView *)scrollView viewForAnnotation:(id<JCAnnotation>)annotation {
    ARAnnotationView *annotationView = (ARAnnotationView *)[scrollView dequeueReusableAnnotationViewWithReuseIdentifier:@"ReuseIdentifier"];
    if (!annotationView) {
        annotationView = [[ARAnnotationView alloc] initWithFrame:CGRectZero annotation:annotation reuseIdentifier:@"ReuseIdentifier"];
    }
    int index = ((ARAnnotation *)annotation).index;
    if (index>=0) {
        ZYMusic *music = [ZYMusicTool musics][index];
        ZYMusic *playingMusic = [ZYMusicTool playingMusic];
        CLBeacon *beacon = ((AppDelegate *)[UIApplication sharedApplication].delegate).nearestBeacon;
        int nearestMark = [PWApplicationUtils getIndexOfMusicForBeacon:beacon];
        if (music == playingMusic) {
            if (index == nearestMark) {
                annotationView.imageView.image = [UIImage imageNamed:@"music_playing_orig"];
            } else {
                annotationView.imageView.image = [UIImage imageNamed:@"music_playing_blue"];
            }
        } else {
            if (index == nearestMark) {
                annotationView.imageView.image = [UIImage imageNamed:@"music_orig"];
            } else {
                annotationView.imageView.image = [UIImage imageNamed:@"music_blue"];
            }
        }
//        annotationView.label.text = music.name;
    } else {
        annotationView.imageView.image = [UIImage imageNamed:@"loction"];
//        annotationView.label.text = @"";
    }
    [annotationView sizeToFit];
    annotationView.annotation = annotation;
    NSLog(@"init annotation %d, point %f %f", ((ARAnnotation*)annotation).index, annotation.contentPosition.x, annotation.contentPosition.y);
    return annotationView;
}

- (void)tiledScrollViewDidZoom:(JCTiledScrollView *)scrollView {
    //update UI
}
- (void)tiledScrollViewDidScroll:(JCTiledScrollView *)scrollView {
    //update UI
}

//- (void)tiledScrollView:(JCTiledScrollView *)scrollView annotationWillDisappear:(id<JCAnnotation>)annotation;
//- (void)tiledScrollView:(JCTiledScrollView *)scrollView annotationDidDisappear:(id<JCAnnotation>)annotation;
//- (void)tiledScrollView:(JCTiledScrollView *)scrollView annotationWillAppear:(id<JCAnnotation>)annotation;
//- (void)tiledScrollView:(JCTiledScrollView *)scrollView annotationDidAppear:(id<JCAnnotation>)annotation;
- (void)tiledScrollView:(JCTiledScrollView *)scrollView didSelectAnnotationView:(JCAnnotationView *)view {
    NSArray *musics = [ZYMusicTool musics];
    ARAnnotation *annotation = view.annotation;
    int index = annotation.index;
    NSLog(@"annotation touched index %d", index);
    if (index<0) return;
    ZYMusic *music = musics[index];
    if (music!=nil) {
        
//        AVAudioPlayer *player = .player;
//        ZYMusic *playingMusic = ((AppDelegate *)[UIApplication sharedApplication].delegate).playingMusic;
//        NSLog(@"annotation touched name %@", music.name);
//        [self resetPlayingMusic];
        
        [ZYMusicTool setPlayingMusic:music];
//        playingMusic = music;
        //开发播放音乐
//        player = [[ZYAudioManager defaultManager] playingMusic:playingMusic.musicId];
//        player.delegate = (id<AVAudioPlayerDelegate>)[UIApplication sharedApplication].delegate;
        
        
        [((AppDelegate *)[UIApplication sharedApplication].delegate) startPlayingMusic];
        [self refreshMusicUI];
//        [_mapScrollView refreshAnnotations];
        [self removeAnnotations];
        [self addAnnotations];
        
//        self.player.delegate = self;
        
        //    self.timeLabel.text = [self stringWithTime:self.player.duration];
        
//        [self addUITimer];
    }
}
//- (void)tiledScrollView:(JCTiledScrollView *)scrollView didDeselectAnnotationView:(JCAnnotationView *)view;

- (void)tiledScrollView:(JCTiledScrollView *)scrollView didReceiveSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    
}
- (void)tiledScrollView:(JCTiledScrollView *)scrollView didReceiveDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
    
}
- (void)tiledScrollView:(JCTiledScrollView *)scrollView didReceiveTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight|UIInterfaceOrientationMaskLandscapeLeft;
}

@end
