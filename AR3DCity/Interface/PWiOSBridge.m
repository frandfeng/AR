//
//  PWiOSBridge.m
//  AR3DCity
//
//  Created by frandfeng on 14/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import "PWiOSBridge.h"
#import "PWUnityMsgManager.h"
#import "PWU3DCodec.h"

@implementation PWiOSBridge

+ (const char *)_UnityIOSChannel:(NSString *)json {
    return [[PWUnityMsgManager sharedInstance] unityMsgDealing:[PWU3DCodec U3DCodec:json]];
}

@end
