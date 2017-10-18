//
//  PWU3DCodec.m
//  PWRouter
//
//  Created by Qifei Wu on 2017/7/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#import "PWU3DCodec.h"

@implementation PWU3DCodec
+(char *) U3DCodec:(NSString *)str {
    const char* string = [str UTF8String];
    if (string == NULL) {
        return NULL;
    }
    
    char* res = (char*)malloc(strlen(string) + 1);
    strcpy(res, string);
    return res;
}

+(NSString *) NSStringCodec:(const char *)str {
    if (str) {
        return [NSString stringWithUTF8String: str];
    } else {
        return [NSString stringWithUTF8String: ""];
    }
}

// 将JSON串转化为字典或者数组
+ (id)toArrayOrNSDictionary:(NSData *)jsonData {
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingAllowFragments
                                                      error:&error];
    
    if (jsonObject != nil && error == nil){
        return jsonObject;
    }else{
        // 解析错误
        return nil;
    }
    
}
@end
