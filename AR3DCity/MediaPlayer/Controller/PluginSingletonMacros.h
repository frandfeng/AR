//
//  PluginSingletonMacros.h
//  PXSJ_plugin
//
//  Created by Qifei Wu on 2017/4/19.
//  Copyright © 2017年 Qifei Wu. All rights reserved.
//

#ifndef PluginSingletonMacros_h
#define PluginSingletonMacros_h


//------------------------单例宏---------------------------
//@interface
#define singleton_interface(className) +(className*) shared##className;

//@implementation
#if __has_feature(objc_arc)

#define singleton_implementation(className)\
static className* _instance;\
\
+(id)allocWithZone:(struct _NSZone*)zone\
{\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
_instance = [super allocWithZone:zone];\
});\
return _instance;\
}\
\
+ (instancetype) shared##className \
{\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
_instance = [[self alloc]init];\
});\
return _instance;\
}\
\
- (id)copyWithZone:(NSZone*)zone\
{\
return _instance;\
}\

#else

#define singleton_implementation(className)\
static className* _instance;\
\
+(id)allocWithZone:(struct _NSZone*)zone\
{\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
_instance = [super allocWithZone:zone];\
});\
return _instance;\
}\
\
+ (instancetype) shared##className \
{\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
_instance = [[self alloc]init];\
});\
return _instance;\
}\
\
- (id)copyWithZone:(NSZone*)zone\
{\
return _instance;\
}\
\
- (oneway void)release { } \
- (id)retain { return self; } \
- (NSUInteger)retainCount { return 1;} \
- (id)autorelease { return self;}

#endif

#endif /* PluginSingletonMacros_h */
