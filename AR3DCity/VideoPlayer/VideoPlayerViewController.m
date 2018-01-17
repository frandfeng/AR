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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight|UIInterfaceOrientationMaskLandscapeLeft;
}

- (void)dealloc {
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
