//
//  ZegoMessage.h
//  InstantTalk
//
//  Created by Strong on 16/7/8.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZegoAVKitManager.h"
#import "ZegoCommand.h"

extern NSString *const kUserUnreadCountUpdateNotification;

//ZegoUser没有实现NSCoding协议，此类主要用来实现coding
@interface ZegoMessageUser : NSObject <NSCoding>
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;
@end

@interface ZegoMessageDetail : NSObject <NSCoding>

- (instancetype)initWithUser:(ZegoUser *)fromUser messageContent:(NSString *)messageContent;

//消息发送者
@property (nonatomic, strong) ZegoUser *fromUser;
//消息发送时间
@property (nonatomic, assign) NSTimeInterval messageTime;
//消息内容
@property (nonatomic, copy) NSString *messageContent;

- (BOOL)isMessageSelfSend;

@end

@interface ZegoMessage : NSObject <NSCoding>

//一个会话窗口为一个session，唯一标记（发起人id+发起时间)
@property (nonatomic, copy) NSString *session;
//此会话的所有成员列表，包括自己
@property (nonatomic, strong) NSMutableArray<ZegoUser *> *memberList;
//此会话窗口的所有聊天记录
@property (nonatomic, strong) NSMutableArray<ZegoMessageDetail *> *messageHistory;
//未读计数
@property (nonatomic, assign) NSUInteger unreadCount;

- (instancetype)initWithSession:(NSString *)sessionID memberList:(NSArray<ZegoUser *> *)memberList;

- (void)addMemberList:(NSArray<ZegoUser *> *)newMember;
- (void)sendMessage:(NSString *)messageContent;

- (void)onRecevieMessage:(NSDictionary *)messageReceiveInfo;

+ (ZegoMessage *)createMessageFromDictionary:(NSDictionary *)dictionary;

@end
