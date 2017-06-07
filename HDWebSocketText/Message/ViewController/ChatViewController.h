//
//  ChatViewController.h
//  HDWebSocketText
//
//  Created by huadong on 2017/6/6.
//  Copyright © 2017年 Simon.H. All rights reserved.
//

#import "JSQMessages.h"
#import "ChatModel.h"
#import "NSUserDefaults+DemoSettings.h"

@class ChatViewController;

@protocol JSQDemoViewControllerDelegate <NSObject>

- (void)didDismissJSQDemoViewController:(ChatViewController *)vc;

@end

@interface ChatViewController : JSQMessagesViewController<UIActionSheetDelegate, JSQMessagesComposerTextViewPasteDelegate>

@property (weak, nonatomic) id<JSQDemoViewControllerDelegate> delegateModal;
@property (strong, nonatomic) ChatModel *chatModel;


@end
