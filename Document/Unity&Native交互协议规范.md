## Unity向原生发消息

Unity向原生发送消息:

1. iOS通过方法 `const char* _UnityIOSChannel(char* json)` 交互

> 参数为json格式数据，最基本的数据格式有method和params键
> 
> 返回值为 String 类型数据，现在有两个值true和false，分别表示消息有没有被原生成功处理

### 查询定位授权的状态

{"method":"ReqGPSState","params":{}}

### 请求原生GPS信息

{"method":"ReqGPSInfo","params":{}}

### 拨打电话号码

{"method":"ReqCallPhone","params":{"phoneNum":"xxxxxxx"}}

### APP界面输出log信息

{"method":"ReqCallLog","params":{"logString":"xxxxxxx"}}

> 如何需要断开debug调试而在APP界面上查看某些log，可以使用此方法打印

### 隐藏或显现播放按钮

{"method":"ReqPlayButton","params":{"appear":"yes/no","animate":"yes/no"}}

### 暂停或播放原生音频

{"method":"ReqPlayMusic","params":{"play":"yes/no"}}


## 原生向Untiy发送消息

原生向Unity发送消息：

1. iOS通过 `UnitySendMessage("", "", "")` 方法交互

> 参数1表示Unity中接收该消息的实例，参数2表示Unity中接收的实例的方法名称，参数3表示该实例方法的参数获取，也为json格式的string

### 发送原生定位授权状态信息

UnitySendMessage("Entrance","OnGPSStateResult",{"params":{"state":"statestring"}})

> statestring 为
> 
> 1. kCLAuthorizationStatusNotDetermined
> 2. kCLAuthorizationStatusDenied
> 3. kCLAuthorizationStatusAuthorizedAlways

### 发送原生定位信息到Unity

UnitySendMessage("Entrance","OnGPSStateResult",{"params":{"longitude":10.1,"latitude":10.1}})