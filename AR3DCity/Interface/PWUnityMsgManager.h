//
//  PWUnityMsgManager.h
//  PWRouter
//
//  Created by Qifei Wu on 2017/7/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PWUnityMsgManagerDelegate <NSObject>

-(void)recvU3DMSG:(NSString *)msg;

@end

@interface PWUnityMsgManager : NSObject
#pragma mark - Singleton
+ (instancetype)sharedInstance;

- (const char *)unityMsgDealing:(const char *) value ;

- (void)sendMsg2Unity:(NSString *)value;

@property (nonatomic, copy) void (^sendUnityMsg)(NSString * obj, NSString * method, NSString * msg);

@property (nonatomic, assign) id<PWUnityMsgManagerDelegate> delegate;
@end
