//
//  ZYMusic.h
//  ZYMusicPlayer
//
//  Created by 王志盼 on 15/10/12.
//  Copyright © 2015年 王志盼. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZYMusicData : NSObject

@property (strong, nonatomic) NSArray *datas;

@end

@interface ZYMusic : NSObject
/**
 *  景点名称
 */
@property (copy, nonatomic) NSString *name;
/**
 *  音乐名称
 */
@property (copy, nonatomic) NSString *musicId;
/**
 *  景点位置
 */
@property (copy, nonatomic) NSString *location;
/**
 *  景点图标
 */
@property (copy, nonatomic) NSString *icon;
/**
 *  景点详情
 */
@property (copy, nonatomic) NSString *detail;

@property (assign, nonatomic, getter = isPlaying) BOOL playing;

@end
