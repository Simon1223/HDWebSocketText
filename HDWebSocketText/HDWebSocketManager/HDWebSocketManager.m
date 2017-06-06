//
//  HDWebSocketManager.m
//  HDWebSocketText
//
//  Created by huadong on 2017/6/6.
//  Copyright © 2017年 Simon.H. All rights reserved.
//

#import "HDWebSocketManager.h"

typedef NS_ENUM(NSInteger, DisconnectType) {
    DisconnectTypeServer = 1001 , //服务器断开连接
    DisconnectTypeClient = 1002 , //客户端断开连接
};

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

@interface HDWebSocketManager ()<SRWebSocketDelegate>

@property (nonatomic, copy) SRWebSocket webSocket;
@property (nonatomic, copy) NSTimer *heartBeat; //心跳计时器
@property (nonatomic, assign) NSTimeInterval reconnectTime; //重连时长

@end

@implementation HDWebSocketManager

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static HDWebSocketManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithWebSocket];
    });
    return instance;
}

- (instancetype)initWithWebSocket
{
    self = [super init];
    if (self) {
        [self initWebSocket];
    }
    
    return self;
}


/**
 初始化建立Socket连接
 */
- (void)initWebSocket
{
    if (_webSocket) {
        return;
    }

    _webSocket = [[SRWebSocket alloc]initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"ws://%@:%d", socketHost, socketPort]]];
    _webSocket.delegate = self;
    
    //设置代理线程queue
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 1;
    
    [_webSocket setDelegateOperationQueue:queue];
    
    //连接
    [_webSocket open];
}

//初始化心跳
- (void)initHeartBeat
{
    dispatch_main_async_safe(^{
        [self destoryHeartBeat];
        
        __weak typeof(self) weakSelf = self;
        //心跳设置为3分钟，NAT超时一般为5分钟
        _heartBeat = [NSTimer scheduledTimerWithTimeInterval:3*60 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"heart");
            //和服务端约定好发送什么作为心跳标识，尽可能的减小心跳包大小
            [weakSelf sendMsg:@"heart"];
        }];
        [[NSRunLoop currentRunLoop] addTimer:_heartBeat forMode:NSRunLoopCommonModes];
    });
}

//销毁心跳
- (void)destoryHeartBeat
{
    dispatch_main_async_safe(^{
        if (_heartBeat) {
            [_heartBeat invalidate];
            _heartBeat = nil;
        }
    });
}


#pragma mark - 对外的一些接口

//建立连接
- (void)connect
{
    [self initWebSocket];
    
    //每次正常连接的时候清零重连时间
    _reconnectTime = 0;
}

//断开连接
- (void)disconnect
{
    if (_webSocket) {
        [_webSocket closeWithCode:DisconnectTypeClient reason:@"客户端主动断开"];
        _webSocket = nil;
    }
}

//发送消息
- (void)sendMessage:(NSData *)message
{
    [webSocket send:message];
}

//重连机制
- (void)reconnect
{
    [self disconnect];
    
    //超过一分钟就不再重连 所以只会重连5次 2^5 = 64
    if (_reconnectTime > MaxReconnectTime) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_reconnectTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _webSocket = nil;
        [self initWebSocket];
    });
    
    //重连时间2的指数级增长
    if (_reconnectTime == 0) {
        _reconnectTime = 2;
    }else{
        _reconnectTime *= 2;
    }
}

//ping
- (void)ping
{
    if (_webSocket) {
        [_webSocket sendPing:nil];
    }
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"服务器返回收到消息:%@",message);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"连接成功");
    //连接成功了开始发送心跳
    [self initHeartBeat];
}

//open失败的时候调用
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"连接失败.....\n%@",error);
    //失败了就去重连
    [self reconnect];
}

//网络连接中断被调用
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    //NSLog(@"被关闭连接，code:%ld,reason:%@,wasClean:%d",code,reason,wasClean);
    
    //如果是被用户自己中断的那么直接断开连接，否则开始重连
    if (code == DisconnectTypeClient) {
        NSLog(@"被用户关闭连接，不重连");
        [self disconnect];
    }else{
        NSLog(@"其他原因关闭连接，开始重连...");
        [self reconnect];
    }
    
    //断开连接时销毁心跳
    [self destoryHeartBeat];
}

//sendPing的时候，如果网络通的话，则会收到回调，但是必须保证ScoketOpen，否则会crash
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    NSLog(@"收到pong回调");
    
}


@end
