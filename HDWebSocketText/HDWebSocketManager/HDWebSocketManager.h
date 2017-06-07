//
//  HDWebSocketManager.h
//  HDWebSocketText
//
//  Created by huadong on 2017/6/6.
//  Copyright © 2017年 Simon.H. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketRocket.h"

static NSString *socketHost = @"127.0.0.1";
static int socketPort = 6969;
static int MaxHeartbeatTime = 3;  //心跳3分钟
static int MaxReconnectTime = 64; //重连64秒

/**
 HDWebSocket管理类
 */
@interface HDWebSocketManager : NSObject
@property (nonatomic, assign) BOOL isConnected;

//单例
+ (instancetype)shareInstance;

//建立连接
- (void)connect;

//断开连接
- (void)disconnect;

//发送Ping
- (void)ping;

//发送数据
- (void)sendMessage:(id)message;

@end
