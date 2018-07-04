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

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    self.player = [[AVPlayer alloc] initWithURL:url];
    return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight|UIInterfaceOrientationMaskLandscapeLeft;
}

- (void)dealloc {
    NSLog(@"VideoPlayerViewController dealloc");
    [[PWUnityMsgManager sharedInstance] sendMsg2UnityOfType:@"OnPlayVideoState" andValue:[NSString stringWithFormat:@"{\"params\":{\"errCode\":\"%@\"}}", @"0"]];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
    [[PWUnityMsgManager sharedInstance] sendMsg2UnityOfType:@"OnPlayVideoState" andValue:[NSString stringWithFormat:@"{\"params\":{\"errCode\":\"%@\"}}", @"0"]];
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