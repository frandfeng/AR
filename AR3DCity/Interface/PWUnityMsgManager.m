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

- (void)sendMsg2Unity:(NSString *)value {
    if (self.sendUnityMsg != nil) {
        NSLog(@"=========== sendMsg2Unity Value :%@",value);
        self.sendUnityMsg(@"Unity",@"sendData", value);
    }
}

-(const char *)unityMsgDealing:(const char *) value {
    NSString *str =[PWU3DCodec NSStringCodec:value];
//    if (self.delegate != nil) {
//        [self.delegate recvU3DMSG:str];
//    }
    NSDictionary *dic = [PWU3DCodec toArrayOrNSDictionary:[str dataUsingEncoding:NSASCIIStringEncoding]];
    if ([[dic allKeys] containsObject:@"method"]) {
        NSString *func = [dic objectForKey:@"method"];
        if ([func isEqualToString:@"ReqIntelligentFun"]) {
            
        }
    }
    return [PWU3DCodec U3DCodec:@"false"];
}
@end
