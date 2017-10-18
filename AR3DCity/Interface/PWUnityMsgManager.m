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
    NSLog(@"发送给Unity消息 方法 %@, 参数 :%@",type, value);
    UnitySendMessage(@"Entrance".UTF8String, type.UTF8String, value.UTF8String);
}

-(const char *)unityMsgDealing:(const char *) value {
    NSString *str =[PWU3DCodec NSStringCodec:value];
    NSLog(@"收到unity消息 %@", str);
    NSDictionary *dic = [PWU3DCodec toArrayOrNSDictionary:[str dataUsingEncoding:NSASCIIStringEncoding]];
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
            [self sendMsg2UnityOfType:@"OnGPSStateResult" andValue:@"{\"params\":{\"isOpened\":true}}"];
        }
        /**
         GPS定位（OnGPSInfoResult是回调函数）
         
         M->Call->A:ReqGPSInfo()->...->A->Call->M:OnGPSInfoResult(float longitude, float latitude)
         
         IOS（特殊处理）:
         U3D->IOS：{"method":"ReqGPSState","params":[]}
         IOS->U3D："Entrance","OnGPSStateResult",{"params":[{"longitude":10.1},{"latitude":10.1}]}
         */
        else if ([func isEqualToString:@"ReqGPSInfo"]) {
            [self sendMsg2UnityOfType:@"OnGPSInfoResult" andValue:@"{\"params\":{\"longitude\":10.2,\"latitude\":10.1}}"];
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
        /**
         打开智能导游窗口和关闭智能导游窗口（OnIntelligentFun是回调函数）
         */
        else if ([func isEqualToString:@"ReqIntelligentFun"]) {
            [self sendMsg2UnityOfType:@"OnIntelligentFun" andValue:@"{\"params\":{}}"];
        }
    }
    return [PWU3DCodec U3DCodec:@"false"];
}
@end
