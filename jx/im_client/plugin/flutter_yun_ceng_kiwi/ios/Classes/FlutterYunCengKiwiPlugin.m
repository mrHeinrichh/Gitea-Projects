#import "FlutterYunCengKiwiPlugin.h"
// #include <YunCeng/YunCeng.h>
#import <Kiwi/Kiwi.h>
#import <Flutter/Flutter.h>

const int kiwi_init_default = -999;
int kiwi_init_value = kiwi_init_default;

@implementation FlutterYunCengKiwiPlugin{
    NSString* _token;
    FlutterMethodChannel *_methodChannel;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"flutter_yun_ceng_kiwi"
            binaryMessenger:[registrar messenger]];
    FlutterYunCengKiwiPlugin* instance = [[FlutterYunCengKiwiPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _methodChannel = channel;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else if ([call.method isEqualToString:@"initEx"]) {
        return [self initEx:call result:result];
    }
    else if ([call.method isEqualToString:@"initAsync"]) {
        return [self initAsync:call result:result];
    }
    else if ([call.method isEqualToString:@"isInitDone"]) {
        return [self isInitDone:call result:result];
    }
    // else if ([call.method isEqualToString:@"initExWithCallback"]) {
    //     return [self initExWithCallback:call result:result];
    //  }
    else if ([call.method isEqualToString:@"getProxyTcpByDomain"]) {
        return [self getProxyTcpByDomain:call result:result];
    }
    else if([call.method isEqualToString:@"restartAllServer"]){
        return [self restartAllServer:call result:result];
    }
    else if([call.method isEqualToString:@"onNetworkOn"]){
        return [self onNetworkOn:call result:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void) restartAllServer:(FlutterMethodCall*)call result:(FlutterResult)result
{
    [Kiwi RestartAllServer];
    NSLog(@"游戏盾网络重置成功");
    result(nil);
}

- (void) onNetworkOn:(FlutterMethodCall*)call result:(FlutterResult)result
{
    [Kiwi OnNetworkOn];
    NSLog(@"游戏盾网络恢复成功");
    result([NSNumber numberWithInt:0]);
}

- (void) initEx:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSDictionary *args = call.arguments;
    _token = args[@"token"];
    NSString* appKey = args[@"appKey"];
    int ret = [Kiwi Init:[appKey UTF8String]];
    kiwi_init_value = ret;
    if (0 != ret) {
        NSLog(@"初始化游戏盾失败:%i, 准备重试!",ret);
    }else{
        NSLog(@"yxd初始化成功%i",ret);
    }
    result([NSNumber numberWithInt:ret]);
}

- (void) initAsync:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSDictionary *args = call.arguments;
    _token = args[@"token"];
    NSString* appKey = args[@"appKey"];
    kiwi_init_value = kiwi_init_default;
    [Kiwi InitWithListener:[appKey UTF8String] :^(int code){
        kiwi_init_value = code;
    }];
    result([NSNumber numberWithInt:0]);
}

- (void) isInitDone:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if (kiwi_init_value != kiwi_init_default) {
        result([NSNumber numberWithInt:0]);
    } else {
        result([NSNumber numberWithInt:-1]);
    }
}

// - (void) initExWithCallback:(FlutterMethodCall*)call result:(FlutterResult)result
// {
//     NSDictionary *args = call.arguments;
//     _token = args[@"token"];
//     NSString* appKey = args[@"appKey"];
    
//     __weak typeof(self) weakSelf = self;
//     [YunCeng initExWithCallback:[appKey UTF8String] :[_token UTF8String] :^(int ret){
//         __strong typeof(self) strongSelf = weakSelf;
//         if (!strongSelf) {
//             return ;
//         }
        
//         if (0 != ret) {
//             NSLog(@"初始化游戏盾失败:%i, 准备重试!",ret);
//         }else{
//             NSLog(@"yxd初始化成功%i",ret);
//         }
//         [strongSelf->_methodChannel invokeMethod:@"initExWithCallbackResult" arguments:[NSNumber numberWithInt:ret]];
//     }];
    
//     result(nil);
// }

-(void) getProxyTcpByDomain:(FlutterMethodCall*)call result:(FlutterResult)result
{
//    if (!_token) {
//        NSLog(@"游戏盾未初始化!");
//        return;
//    }
    
    NSDictionary *args = call.arguments;
    NSString* token = _token;
    NSString* groupName = args[@"group_name"];
    NSString* ddomain = args[@"ddomain"];
    NSString* dPort = args[@"dport"];
    
    char ip[128]= {0};
    char port[40] = {0};
    int ret = [Kiwi ServerToLocal :[groupName UTF8String] : ip : sizeof(ip) : port:sizeof(port)];
    
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject: [NSString stringWithFormat:@"%i",ret] forKey:@"code"];
    [dic setObject: [NSString stringWithUTF8String:ip] forKey:@"target_ip"];
    [dic setObject: [NSString stringWithUTF8String:port] forKey:@"target_port"];
    result(dic);
}


-(BOOL)isNull:(NSMutableDictionary *)dict key:(NSString*)key{
    // judge nil
    if(![dict objectForKey:key]){
        return NO;
    }
    id obj = [dict objectForKey:key];// judge NSNull
    
    BOOL isNull = [obj isEqual:[NSNull null]];
    return isNull;
}

@end
