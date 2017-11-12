//
//  PWApplicationUtils.m
//  AR3DCity
//
//  Created by frandfeng on 14/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import "PWApplicationUtils.h"
#import "ZYMusicTool.h"
#import "iConsole.h"
#import "ZYMusic.h"
#import <CoreLocation/CoreLocation.h>

@implementation PWApplicationUtils

#pragma mark - Singleton Instance
static PWApplicationUtils *sharedObject = nil;
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

// 获取当前处于activity状态的view controller
- (UIViewController *)activityViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if(window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow *tmpWin in windows) {
            if(tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    
    return [self p_nextTopForViewController:window.rootViewController];
}

- (UIViewController *)p_nextTopForViewController:(UIViewController *)inViewController {
    while (inViewController.presentedViewController) {
        inViewController = inViewController.presentedViewController;
    }
    
    if ([inViewController isKindOfClass:[UITabBarController class]]) {
        UIViewController *selectedVC = [self p_nextTopForViewController:((UITabBarController *)inViewController).selectedViewController];
        return selectedVC;
    }
    else if ([inViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *selectedVC = [self p_nextTopForViewController:((UINavigationController *)inViewController).visibleViewController];
        return selectedVC;
    }
    else {
        return inViewController;
    }
}

+ (int)getIndexOfMusicForBeacon:(CLBeacon *)beacon {
    for (int i=0; i<[ZYMusicTool musics].count; i++) {
        ZYMusic *music = [ZYMusicTool musics][i];
        if ([music.uuid isEqualToString:beacon.proximityUUID.UUIDString]) {
            return i;
        }
    }
}

+ (int)getIndexOfMusicForLocation:(CLLocation *)location {
    int index = -1;
    int distance = 10000000;
    for (int i=0; i<[ZYMusicTool musics].count; i++) {
        ZYMusic *music = [ZYMusicTool musics][i];
        NSArray *array = [music.location componentsSeparatedByString:@","];
        if (array!=nil && array.count>1) {
            CLLocation *placeLoc = [[CLLocation alloc] initWithLatitude:[array[1] doubleValue]  longitude:[array[0] doubleValue]];
            int distanceTemp = [self distanceFromLocation:placeLoc andLoctaion:location];
            if (distanceTemp<distance) {
                distance = distanceTemp;
                index = i;
            }
        }
    }
    ZYMusic *music = nil;
    if (index>=0 && distance<30) {
        music = [ZYMusicTool musics][index];
        [iConsole log:@"离我 30m 以内最近的景点是'%@', 距离为 %d m", music.name, distance];
    } else if (index>=0) {
        music = [ZYMusicTool musics][index];
        index = -1;
        [iConsole log:@"离我最近的景点是'%@', 距离为%dm", music.name, distance];
    } else {
        [iConsole log:@"没有找到附近的景点信息"];
    }
    return index;
}

+ (CLLocationDistance)distanceFromLocation:(CLLocation *)firstLocation andLoctaion:(CLLocation *)secondLocation {
    CLLocationDistance meters= [firstLocation distanceFromLocation:secondLocation];
    return meters;
}


+ (UIImage*)getSquareImage:(UIImage *)image RangeCGRect:(CGRect)range centerBool:(BOOL)centerBool {
    float imgWidth = image.size.width;
    float imgHeight = image.size.height;
    float viewWidth =range.size.width;
    float viewHidth =range.size.height;
    CGRect rect;
    if (centerBool) {
        rect = CGRectMake((imgWidth-viewWidth)/2,(imgHeight-viewHidth)/2,viewWidth,viewHidth);
    } else {
        if (viewHidth) {
            if(imgWidth<= imgHeight) {
                rect = CGRectMake(0,0,imgWidth, imgWidth*viewHidth/viewWidth);
            } else {
                float width = viewWidth*imgHeight/viewHidth;
                float x = (imgWidth - width)/2;
                if (x >0) {
                    rect =CGRectMake(x,0, width, imgHeight);
                } else {
                    rect=CGRectMake(0,0,imgWidth, imgWidth*viewHidth/viewWidth);
                }
            }
        } else {
            if (imgWidth<= imgHeight) {
                float height = viewHidth*imgWidth/viewWidth;
                if (height < imgHeight) {
                    rect =CGRectMake(0,0,imgWidth, height);
                } else {
                    rect =CGRectMake(0,0,viewWidth*imgHeight/viewHidth,imgHeight);
                }
            } else {
                float width = viewWidth*imgHeight/viewHidth;
                if(width < imgWidth) {
                    float x = (imgWidth - width)/2;
                    rect =CGRectMake(x,0,width, imgHeight);
                } else {
                    rect =CGRectMake(0,0,imgWidth, imgHeight);
                }
            }
        }
    }
    
    CGImageRef SquareImageRef = CGImageCreateWithImageInRect(image.CGImage,rect);
    CGRect SquareImageBounds =CGRectMake(0,0,CGImageGetWidth(SquareImageRef),CGImageGetHeight(SquareImageRef));
    UIGraphicsBeginImageContext(SquareImageBounds.size);
    CGContextRef context =UIGraphicsGetCurrentContext();
    CGContextDrawImage(context,SquareImageBounds,SquareImageRef);

    UIImage* SquareImage = [UIImage imageWithCGImage:SquareImageRef];
    UIGraphicsEndImageContext();
    return SquareImage;
}

+ (UIImage*)getClearRectImage:(UIImage*)image {
    UIGraphicsBeginImageContextWithOptions(image.size,NO,0.0f);
    CGContextRef ctx =UIGraphicsGetCurrentContext();
    //默认绘制的内容尺寸和图片一样大,从某一点开始绘制
    [image drawAtPoint:CGPointZero];
    CGFloat bigRaduis = image.size.width/5;
    CGRect cirleRect =CGRectMake(image.size.width/2-bigRaduis, image.size.height/2-bigRaduis, bigRaduis*2, bigRaduis*2);
    //CGContextAddArc(ctx,image.size.width/2-bigRaduis,image.size.height/2-bigRaduis, bigRaduis, 0.0, 2*M_PI, 0);
    CGContextAddEllipseInRect(ctx,cirleRect);
    CGContextClip(ctx);
    CGContextClearRect(ctx,cirleRect);
    UIImage*newImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
