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
        if ([func isEqualToString:@"ReqIntelligentFun"]) {
            
        } else if ([func isEqualToString:@"ReqGPSState"]) {
            [self sendMsg2UnityOfType:@"OnGPSStateResult" andValue:@"{\"params\":{\"isOpened\":true}}"];
        }
    }
    return [PWU3DCodec U3DCodec:@"false"];
}
@end
