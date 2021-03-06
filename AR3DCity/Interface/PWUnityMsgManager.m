//
//  PWUnityMsgManager.m
//  PWRouter
//
//  Created by Qifei Wu on 2017/7/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#import "PWUnityMsgManager.h"
#import "PWU3DCodec.h"
#import <objc/objc.h>
#import "ZYPlayingViewController.h"
#import "PWApplicationUtils.h"
#import "AppDelegate.h"
#import "iConsole.h"
#import "LocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "VideoPlayerViewController.h"
#import "AppDelegate+VideoView.h"

@implementation PWUnityMsgManager

#pragma mark - Singleton Instance
static PWUnityMsgManager *sharedObject = nil;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[super alloc] init];
    });
    return sharedObject;
}

+ (instancetype)alloc {
    @synchronized(self) {
        return [self sharedInstance];
    }
    return nil;
}

- (void)sendMsg2UnityOfType:(NSString *)type andValue:(NSString *)value {
    [iConsole info:@"原生发送给Unity消息 方法 %@, 参数 :%@",type, value];
    UnitySendMessage(@"Entrance".UTF8String, type.UTF8String, value.UTF8String);
}

-(const char *)unityMsgDealing:(const char *) value {
    NSString *str =[PWU3DCodec NSStringCodec:value];
    [iConsole info:@"原生收到Unity消息 %@", str];
    NSDictionary *dic = [PWU3DCodec toArrayOrNSDictionary:[str dataUsingEncoding:NSUTF8StringEncoding]];
    if ([[dic allKeys] containsObject:@"method"]) {
        NSString *func = [dic objectForKey:@"method"];
        /**
         开起定位服务 （OnGPSStateResult是回调函数）
         M->Call->A:ReqGPSState()->...->A->Call->M:OnGPSStateResult(bool isOpened)
         
         IOS（特殊处理）:
         U3D->IOS：{"method":"ReqGPSState","params":[]}
         IOS->U3D："Entrance","OnGPSStateResult",{"params":[{"isOpened":true}]}
         */
        if ([func isEqualToString:@"ReqGPSState"]) {
            CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
            NSString *statusStr = @"";
            switch (status) {
                case kCLAuthorizationStatusNotDetermined: {
                    NSLog(@"用户还没有设置是否授权定位服务");
                    statusStr = @"kCLAuthorizationStatusNotDetermined";
                }
                    break;
                case kCLAuthorizationStatusRestricted: {
                    NSLog(@"用户定位服务受限制（非用户主观）");
                    statusStr = @"kCLAuthorizationStatusNotDetermined";
                }
                    break;
                case kCLAuthorizationStatusDenied: {
                    NSLog(@"用户禁止使用定位服务");
                    statusStr = @"kCLAuthorizationStatusDenied";
                }
                    break;
                case kCLAuthorizationStatusAuthorizedAlways: {
                    NSLog(@"用户允许使用定位服务（包括后台运行）");
                    statusStr = @"kCLAuthorizationStatusAuthorizedAlways";
                }
                    break;
                case kCLAuthorizationStatusAuthorizedWhenInUse: {
                    NSLog(@"用户允许在使用程序时使用定位服务");
                    statusStr = @"kCLAuthorizationStatusAuthorizedAlways";
                }
                    break;
                default:
                    break;
            }
            [self sendMsg2UnityOfType:@"OnGPSStateResult" andValue:[NSString stringWithFormat:@"{\"params\":{\"state\":\"%@\"}}", statusStr]];
            return [PWU3DCodec U3DCodec:@"true"];
        }
        /**
         GPS定位（OnGPSInfoResult是回调函数）
         
         M->Call->A:ReqGPSInfo()->...->A->Call->M:OnGPSInfoResult(float longitude, float latitude)
         
         IOS（特殊处理）:
         U3D->IOS：{"method":"ReqGPSState","params":[]}
         IOS->U3D："Entrance","OnGPSStateResult",{"params":[{"longitude":10.1},{"latitude":10.1}]}
         */
        else if ([func isEqualToString:@"ReqGPSInfo"]) {
            LocationManager *locManager = [[LocationManager alloc] init];
            [locManager startLocation:^(NSArray<CLLocation *> *locations) {
                if (locations!=nil&&locations.count>0) {
                    CLLocation *currentLoc = [locations firstObject];
                    [self sendMsg2UnityOfType:@"OnGPSInfoResult" andValue:[NSString stringWithFormat:@"{\"params\":{\"longitude\":%lf,\"latitude\":%lf}}", currentLoc.coordinate.longitude, currentLoc.coordinate.latitude]];
                }
            }];
            return [PWU3DCodec U3DCodec:@"true"];
        }
        /**
         打电话
         M->Call->A:ReqCallPhone(string phoneNum)
         
         IOS（特殊处理）:
         U3D->IOS：{"method":"ReqCallPhone","params":{"phoneNum":"123456789012"}}
         
         */
        else if ([func isEqualToString:@"ReqCallPhone"]) {
            if ([[dic allKeys] containsObject:@"params"]) {
                NSDictionary *paramsDic = [dic objectForKey:@"params"];
                if ([[paramsDic allKeys] containsObject:@"phoneNum"]) {
                    NSString *phoneNum = paramsDic[@"phoneNum"];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel://" stringByAppendingString:phoneNum]]];
                    return [PWU3DCodec U3DCodec:@"true"];
                }
            }
        }
        else if([func isEqualToString:@"ReqCallLog"]) {
            if ([[dic allKeys] containsObject:@"params"]) {
                NSDictionary *paramsDic = [dic objectForKey:@"params"];
                if ([[paramsDic allKeys] containsObject:@"logString"]) {
                    NSString *logStr = paramsDic[@"logString"];
                    [iConsole log:@"UNITY LOG: %@", logStr];
                    return [PWU3DCodec U3DCodec:@"true"];
                }
            }
        }
        else if ([func isEqualToString:@"ReqPlayMusic"]) {
            if ([[dic allKeys] containsObject:@"params"]) {
                NSDictionary *paramsDic = [dic objectForKey:@"params"];
                if ([[paramsDic allKeys] containsObject:@"play"]) {
                    NSString *play = paramsDic[@"play"];
                    [(AppDelegate *)[UIApplication sharedApplication].delegate audioPlayerInterruptionOfUnity:[play isEqualToString:@"True"]];
                    return [PWU3DCodec U3DCodec:@"true"];
                }
            }
        }
        else if ([func isEqualToString:@"ReqPlayButton"]) {
            if ([[dic allKeys] containsObject:@"params"]) {
                NSDictionary *paramsDic = [dic objectForKey:@"params"];
                if ([[paramsDic allKeys] containsObject:@"appear"]) {
                    NSString *appear = paramsDic[@"appear"];
                    NSString *animate = paramsDic[@"animate"];
                    if ([appear isEqualToString:@"True"]) {
                        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"cutFinish"]) {
                            [(AppDelegate *)[UIApplication sharedApplication].delegate bringButtonToFront:[animate isEqualToString:@"True"]];
                        } else {
                            NSLog(@"cut not finish, show later");
                        }
                    } else {
                        [(AppDelegate *)[UIApplication sharedApplication].delegate hideButton:[animate isEqualToString:@"True"]];
                    }
                    return [PWU3DCodec U3DCodec:@"true"];
                }
            }
        }
        else if ([func isEqualToString:@"ReqPlayVideo"]) {
            if ([[dic allKeys] containsObject:@"params"]) {
                NSDictionary *paramsDic = [dic objectForKey:@"params"];
                if ([[paramsDic allKeys] containsObject:@"videoName"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *videoName = paramsDic[@"videoName"];
                        NSURL *url = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"Data/Raw/Video/%@", videoName] withExtension:@"mp4"];
                        int progress = 0;
                        if ([paramsDic.allKeys containsObject:@"progress"]) {
                            NSString *progStr = paramsDic[@"progress"];
                            progress = progStr.intValue;
                        }
                        if (progress==-1) {
                            [(AppDelegate *)[UIApplication sharedApplication].delegate setVideoUrl:url];
                            [(AppDelegate *)[UIApplication sharedApplication].delegate startPlayVideo];
                        } else {
                            VideoPlayerViewController *avPlayerVc = [[VideoPlayerViewController alloc] initWithUrl:url andProgress:progress];
                            [[PWApplicationUtils sharedInstance].activityViewController presentViewController:avPlayerVc animated:YES completion:nil];
                        }
                    });
                    return [PWU3DCodec U3DCodec:@"true"];
                }
            }
        }
        else if ([func isEqualToString:@"ReqARScan"]) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                ImageTargetsViewController *arScanVc = [[ImageTargetsViewController alloc] init];
//                [[PWApplicationUtils sharedInstance].activityViewController presentViewController:arScanVc animated:YES completion:nil];
//            });
        }
        else if ([func isEqualToString:@"ReqARNavigate"]) {
            if ([[dic allKeys] containsObject:@"params"]) {
                NSDictionary *paramsDic = [dic objectForKey:@"params"];
                if ([[paramsDic allKeys] containsObject:@"stop"]) {
                    if ([[paramsDic allKeys] containsObject:@"stop"]) {
                        NSString *stop = paramsDic[@"stop"];
                        if ([stop isEqualToString:@"True"]) {
                            ((AppDelegate *)[UIApplication sharedApplication].delegate).navOpen = NO;
                        } else {
                            ((AppDelegate *)[UIApplication sharedApplication].delegate).navOpen = YES;
                        }
                        return [PWU3DCodec U3DCodec:@"true"];
                    }
                    return [PWU3DCodec U3DCodec:@"true"];
                }
            }
        }
        else if ([func isEqualToString:@"ReqShutdownVideo"]) {
            if ([[dic allKeys] containsObject:@"params"]) {
                NSDictionary *paramsDic = [dic objectForKey:@"params"];
                if ([[paramsDic allKeys] containsObject:@"resetposition"]) {
                    NSString *resetposition = paramsDic[@"resetposition"];
                    if ([resetposition isEqualToString:@"True"]) {
                        [(AppDelegate *)[UIApplication sharedApplication].delegate stopPlayVideo];
                    } else {
                        [(AppDelegate *)[UIApplication sharedApplication].delegate pausePlayVideo];
                    }
                }
            }
        }
    }
    return [PWU3DCodec U3DCodec:@"false"];
}
@end
