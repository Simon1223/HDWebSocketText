//
//  ChatModel.h
//  HDWebSocketText
//
//  Created by huadong on 2017/6/6.
//  Copyright © 2017年 Simon.H. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"

/**
 *  消息动作
 */
typedef NS_ENUM(NSInteger, MessageAction){
    
    MessageActionIncoming  =0,  //接收消息
    MessageActionOutgoing  =1,  //发送消息
    MessageActionCentering =2,  //卡片消息
};


/**
 *  消息内容类型
 */
typedef NS_ENUM(NSInteger, MessageContentType){
    
    MessageContentTypeText            =0, //文字
    MessageContentTypePhoto           =1, //图片
    MessageContentTypeVoice           =2, //语音
    MessageContentTypeVideo           =3, //视频
    MessageContentTypeLocation        =4, //位置
};

/**
 *  发送消息状态
 */
typedef NS_ENUM(NSInteger, MessageSendStatus){
    
    MessageSendStatusNone    = 0, //无发送状态
    MessageSendStatusSending = 1, //发送中
    MessageSendStatusSuccess = 2, //发送成功
    MessageSendStatusFailure = 3  //发送失败
};


@interface ChatModel : NSObject

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) NSMutableArray *messages;

/*
 * 消息动作类型
 */
@property(nonatomic) MessageAction messageAction;

/*
 * 消息内容类型
 */
@property(nonatomic) MessageContentType contentType;


/**
 *  消息发送状态
 */
@property (nonatomic) MessageSendStatus sendStatus;

/*
 * 多媒体内容
 */
@property(nonatomic,strong) NSString *mediaContent;


/*
 * 多媒体本地路径
 */
@property(nonatomic,strong) NSString *localPath;

/*
 * 多媒体对象
 */
@property (copy, nonatomic) id<JSQMessageMediaData> media;


/*
 * 是否是多媒体消息
 */
@property (nonatomic,assign) BOOL isMediaMessage;



/*
 * 发送显示名称
 */
@property (nonatomic,strong) NSString *senderDisplayName;


/*
 * 发送者Id
 */
@property(nonatomic,strong) NSString *senderId;


/*
 * 接收者Id
 */
@property(nonatomic,strong) NSString *receiverId;

/*
 * 接收语音是否播放
 */
@property(nonatomic) BOOL receiveVoicePlayed;


/*
 * 响应需求是否查看
 */
@property(nonatomic) BOOL isReadDemand;

/**
 *  显示时间
 */
@property(nonatomic,strong) NSString *showDate;

- (void)addPhotoMediaMessage;

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;

- (void)addVideoMediaMessage;

- (void)addVideoMediaMessageWithThumbnail;

- (void)addAudioMediaMessage;

@end


