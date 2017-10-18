//
//  PWU3DCodec.h
//  PWRouter
//
//  Created by Qifei Wu on 2017/7/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWU3DCodec : NSObject

+(char *) U3DCodec:(NSString *)str;
+(NSString *) NSStringCodec:(const char *)str;

+ (id)toArrayOrNSDictionary:(NSData *)jsonData;
@end
