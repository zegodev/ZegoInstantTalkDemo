//
//  ZegoDataCenter.h
//  InstantTalk
//
//  Created by Strong on 16/7/7.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZegoAVKitManager.h"
#import "ZegoMessage.h"
#import "ZegoVideoCommand.h"

extern NSString *const kUserUpdateNotification;
extern NSString *const kUserLoginNotification;
extern NSString *const kUserDisconnectNotification;
extern NSString *const kUserMessageReceiveNotification;
extern NSString *const kUserMessageSendNotification;
extern NSString *const kUserRequestVideoTalkNotification;
extern NSString *const kUserAcceptVideoTalkNotification;
extern NSString *const kUserLeaveRoomNotification;
extern NSString *const kUserRespondVideoTalkNotification;
extern NSString *const kUserCancelVideoTalkNotification;
extern NSString *const kUserClearAllSessionNotification;
//extern NSString *const kUserRequestWhileTalkingNotification;

@interface ZegoUserInfo : NSObject

@property (nonatomic, assign) unsigned int userIndex;
@property (nonatomic, strong) ZegoUser *user;

@end

@interface ZegoDataCenter : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign, readonly) BOOL isLogin;

//当前在线用户列表
@property (nonatomic, strong, readonly) NSMutableArray<ZegoUserInfo*> *userList;
//聊天记录
@property (nonatomic, strong, readonly) NSMutableArray<ZegoMessage *> *sessionList;

- (void)loginRoom;
- (void)leaveRoom;

//创建一个session (发起多人会话时每次都创建一个sesssion，单人会话从历史记录中查找）
- (NSString *)createSessionWithMemberList:(NSArray<ZegoUser *> *)memberList;
//获取一个session(单人会话）
- (NSString *)getSessionID:(NSString *)userID;
//一个session中删除成员(暂不提供删除接口)
//- (void)removeMember:(NSArray<ZegoUser *> *)removeMemberList sessionID:(NSString *)sessionID;
//一个session中增加成员
- (void)addMember:(NSArray<ZegoUser *> *)addMemberList  sessionID:(NSString *)sessionID;
//向一个session发送消息
- (void)sendMessage:(NSString *)sessionID messageContent:(NSString *)messageContent;
//清除一个session的未读计数
- (void)clearUnreadCount:(NSString *)sessionID;
//获取所有的未读计数
- (NSUInteger)getTotalUnreadCount;
//删除一个session
- (void)deleteMessageHistory:(ZegoMessage *)message;
//删除所有session
- (void)clearAllSession;

//根据session获取当前成员列表
- (NSArray<ZegoUser *> *)getMemberList:(NSString *)sessionID;
//根据session获取当前聊天记录
- (NSArray<ZegoMessageDetail*> *)getMessageList:(NSString *)sessionID;
//根据session获取当前message
- (ZegoMessage *)getMessageInfo:(NSString *)sessionID;

//单人会话时，获取成员列表中另外一个成员
- (ZegoUser *)getOtherUser:(NSArray<ZegoUser *> *)memberList;

//保存所有会话记录到本地
- (void)saveSessionList;

//判断用户是否在线
- (BOOL)isUserOnline:(NSString *)userID;
//判断成员列表是否有人在线
//YES: 至少有人在线(除用户自己外)
//NO: 没有任何人在线
- (BOOL)isMemberOnline:(NSArray<ZegoUser *> *)userList;

//用户发起视频聊天请求
- (void)requestVideoTalk:(NSArray<ZegoUser *> *)userList;
- (void)stopVideoTalk;
- (void)cancelVideoTalk:(NSArray<ZegoUser *> *)userList;

//用户同意/拒绝视频聊天
- (void)agreedVideoTalk:(BOOL)agreed magicNumber:(NSString *)magicNumber;

- (void)registerPrivateRoomDelegate:(id<BizRoomStreamDelegate>)privateDelegate;

- (void)contactUs;


@end
