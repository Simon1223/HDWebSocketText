//
//  ChatModel.h
//  HDWebSocketText
//
//  Created by huadong on 2017/6/6.
//  Copyright © 2017年 Simon.H. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"

static NSString * const kJSQDemoAvatarDisplayNameSquires = @"Jesse Squires";
static NSString * const kJSQDemoAvatarDisplayNameCook = @"Tim Cook";
static NSString * const kJSQDemoAvatarDisplayNameJobs = @"Jobs";
static NSString * const kJSQDemoAvatarDisplayNameWoz = @"Steve Wozniak";

static NSString * const kJSQDemoAvatarIdSquires = @"053496-4509-289";
static NSString * const kJSQDemoAvatarIdCook = @"468-768355-23123";
static NSString * const kJSQDemoAvatarIdJobs = @"707-8956784-57";
static NSString * const kJSQDemoAvatarIdWoz = @"309-41802-93823";

@interface ChatModel : NSObject

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSDictionary *avatars;
@property (strong, nonatomic) NSDictionary *users;


- (void)addPhotoMediaMessage;

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;

- (void)addVideoMediaMessage;

- (void)addVideoMediaMessageWithThumbnail;

- (void)addAudioMediaMessage;

@end


