//
//  VideoPlayerViewController.m
//  AR3DCity
//
//  Created by frandfeng on 08/01/2018.
//  Copyright © 2018 JingHeQianCheng. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "PWUnityMsgManager.h"

@interface VideoPlayerViewController ()

@end

@implementation VideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.videoGravity = AVLayerVideoGravityResize;
    [self.player play];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)playerItemDidReachEnd:(id)object {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"VideoPlayerViewController didReceiveMemoryWarning");
}

- (instancetype)initWithUrl:(NSURL *)url andProgress:(int)millionSec {
    self = [super init];
    self.player = [[AVPlayer alloc] initWithURL:url];
    NSLog(@"VideoPlayerViewController seek progress %d", millionSec);
    [self.player seekToTime:CMTimeMake(millionSec/1000, 1)];
    return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight|UIInterfaceOrientationMaskLandscapeLeft;
}

- (void)dealloc {
    NSLog(@"VideoPlayerViewController dealloc");
    float progress = CMTimeGetSeconds(self.player.currentItem.currentTime) * 1000;
    NSString *prog = [NSString stringWithFormat:@"%f", progress];
    NSLog(@"VideoPlayerViewController progress %@", prog);
    [[PWUnityMsgManager sharedInstance] sendMsg2UnityOfType:@"OnPlayVideoState" andValue:[NSString stringWithFormat:@"{\"params\":{\"errCode\":\"%@\"}}", prog]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
