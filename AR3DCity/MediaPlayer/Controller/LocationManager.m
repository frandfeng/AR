//
//  LocationManager.m
//  PXSJ_plugin
//
//  Created by Liang on 17/4/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#import "LocationManager.h"
#import <UIKit/UIKit.h>
#import "iConsole.h"

static LocationManager *_shareInstance = nil;

@interface LocationManager ()<CLLocationManagerDelegate, UIAlertViewDelegate>


//返回定位坐标
@property (nonatomic, strong) LocationBlock locationBlock;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation LocationManager
singleton_implementation(LocationManager)

-(instancetype) init {
    self = [super init];
    if (self != nil) {
        [self setupLocationManager];
    }
    return  self;
}

- (void)setupLocationManager {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    _locationManager.distanceFilter = 5.0;
}
//开启定位
- (void)startLocation:(LocationBlock)locationBlock {
    self.locationBlock = locationBlock;
    [self requestLocationAuth];
    [self.locationManager startUpdatingLocation];
}

//结束定位
- (void)stopLocation {
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (self.locationBlock == nil) {
        return;
    }
    self.locationBlock(locations);
    self.locationBlock = nil;
}

-(void)reverseLocation:(CLLocationCoordinate2D) coordinate block:(ReverseGeoBlock)reverseblock {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CLGeocoder *geoC = [[CLGeocoder alloc] init];
    
    [geoC reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"reverseGeocodeLocation :%@", error);
            reverseblock(nil);
            return ;
        }
        
        reverseblock(placemarks);
    }];
}

//定位服务是否可用 如不可用则请求授权 并输出当前权限状态
- (BOOL)isLocationAuthed {
    //定位服务是否可用
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    return status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (void)requestLocationAuth {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"用户还没有设置是否授权定位服务");
        }
            break;
        case kCLAuthorizationStatusRestricted: {
            NSLog(@"用户定位服务受限制（非用户主观）");
        }
            break;
        case kCLAuthorizationStatusDenied: {
            NSLog(@"用户禁止使用定位服务");
        }
            break;
        case kCLAuthorizationStatusAuthorizedAlways: {
            NSLog(@"用户允许使用定位服务（包括后台运行）");
        }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            NSLog(@"用户允许在使用程序时使用定位服务");
        }
            break;
        default:
            break;
    }
    
    if(status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }else if(status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        self.locationBlock(nil);
        self.locationBlock = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        if (self.locationBlock == nil) {
            return;
        }
        self.locationBlock(nil);
        self.locationBlock = nil;
    }
}

@end
