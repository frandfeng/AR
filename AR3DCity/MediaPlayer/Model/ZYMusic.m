//
//  ZYMusic.m
//  ZYMusicPlayer
//
//  Created by 王志盼 on 15/10/12.
//  Copyright © 2015年 王志盼. All rights reserved.
//

#import "ZYMusic.h"

@implementation ZYMusicData

+ (NSDictionary *)objectClassInArray {
    return @{
             @"datas" : [ZYMusic class]
             };
}

@end

@implementation ZYMusic

+ (NSDictionary *)replacedKeyFromPropertyName{
    return @{
             @"musicId" : @"id"
             };
}

@end
