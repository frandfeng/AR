//
//  LocationManager.h
//  PXSJ_plugin
//
//  Created by Liang on 17/4/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "PluginSingletonMacros.h"

typedef void (^LocationBlock)(NSArray<CLLocation *>* locations);
typedef void (^ReverseGeoBlock)(NSArray<CLPlacemark *> * placeMarks);

@interface LocationManager : NSObject
singleton_interface(LocationManager)


//需要配置plist
//获取定位服务是否可用 如不可用则请求授权 并输出当前权限状态到日志
- (BOOL)isLocationAuthed;

//开启定位
- (void)startLocation:(LocationBlock)locationBlock;

//结束定位
- (void)stopLocation;

//返回定位街道
-(void)reverseLocation:(CLLocationCoordinate2D) coordinate block:(ReverseGeoBlock)reverseblock;

@end
