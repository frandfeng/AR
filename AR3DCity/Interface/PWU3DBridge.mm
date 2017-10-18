//
//  PWU3DBridge.m
//  PWRouter
//
//  Created by Qifei Wu on 2017/7/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PWUnityMsgManager.h"

#ifdef __cplusplus
extern "C" {
#endif
    const char* _UnityIOSChannel(char* json);
#ifdef __cplusplus
}
#endif

const char* _UnityIOSChannel(char* json) {
    return [[PWUnityMsgManager sharedInstance] unityMsgDealing:json];
}
