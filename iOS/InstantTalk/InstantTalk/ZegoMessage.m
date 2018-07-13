//
//  ZegoMessage.m
//  InstantTalk
//
//  Created by Strong on 16/7/8.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import "ZegoMessage.h"
#import "ZegoSettings.h"

NSString *const kUserUnreadCountUpdateNotification = @"unreadCountUpdate";

@implementation ZegoMessageUser

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.userID forKey:@"userID"];
    [aCoder encodeObject:self.userName forKey:@"userName"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.userID = [aDecoder decodeObjectForKey:@"userID"];
        self.userName = [aDecoder decodeObjectForKey:@"userName"];
    }
    
    return self;
}

@end

@implementation ZegoMessageDetail

- (instancetype)initWithUser:(ZegoUser *)fromUser messageContent:(NSString *)messageContent
{
    self = [super init];
    if (self)
    {
        self.fromUser = fromUser;
        self.messageContent = messageContent;
        self.messageTime = [[NSDate date] timeIntervalSince1970];
    }
    
    return self;
}

- (BOOL)isMessageSelfSend
{
    if ([self.fromUser.userID isEqualToString:[ZegoSettings sharedInstance].userID])
        return YES;
    
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    ZegoMessageUser *messageUser = [ZegoMessageUser new];
    messageUser.userID = self.fromUser.userID;
    messageUser.userName = self.fromUser.userName;
    [aCoder encodeObject:messageUser forKey:@"fromUser"];
    [aCoder encodeDouble:self.messageTime forKey:@"time"];
    [aCoder encodeObject:self.messageContent forKey:@"content"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        ZegoMessageUser *messageUer = [aDecoder decodeObjectForKey:@"fromUser"];
        self.fromUser = [ZegoUser new];
        self.fromUser.userID = messageUer.userID;
        self.fromUser.userName = messageUer.userName;
        
        self.messageTime = [aDecoder decodeDoubleForKey:@"time"];
        self.messageContent = [[aDecoder decodeObjectForKey:@"content"] copy];
    }
    
    return self;
}

@end

@implementation ZegoMessage

- (instancetype)initWithSession:(NSString *)sessionID memberList:(NSArray<ZegoUser *> *)memberList
{
    self = [super init];
    if (self)
    {
        self.session = sessionID;
        self.memberList = [NSMutableArray arrayWithArray:memberList];
        self.messageHistory = [NSMutableArray array];
    }
    
    return self;
}

- (void)addMemberList:(NSArray<ZegoUser *> *)newMember
{
    NSArray *idsArray = [self.memberList valueForKey:@"userID"];
    NSArray *fileteredArray = [newMember filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NONE (userID IN %@)", idsArray]];
    
    [self.memberList addObjectsFromArray:fileteredArray];
}

- (void)sendMessage:(NSString *)messageContent
{
    if (messageContent.length == 0)
        return;
    
    NSArray *notSelfMemberArray = [self.memberList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userID != %@", [ZegoSettings sharedInstance].userID]];
    NSString *sendContent = [self formatMessage:messageContent toUserList:notSelfMemberArray];
    [getBizRoomInstance() sendBroadcastTextMsgInChatRoom:sendContent isPublicRoom:YES];
    
    //增加一条messageHistory
    if (self.messageHistory == nil)
        self.messageHistory = [NSMutableArray array];
    
    ZegoMessageDetail *detail = [[ZegoMessageDetail alloc] initWithUser:[[ZegoSettings sharedInstance] getZegoUser] messageContent:messageContent];
    //按时间顺序插入
    [self.messageHistory addObject:detail];
}


- (NSString *)formatMessage:(NSString *)messageContent toUserList:(NSArray<ZegoUser*> *)toUsers
{
    if (messageContent.length == 0)
        return nil;
    if (toUsers.count == 0)
        return nil;
    
    //command
    NSMutableDictionary *messageSendInfo = [NSMutableDictionary dictionary];
    messageSendInfo[kZEGO_TALK_CMD] = kZEGO_MESSAGE_COMMAND;
    
    //sessionID
    messageSendInfo[kZEGO_MESSAGE_SESSION] = self.session;
    
    //from user
    NSDictionary *fromUser = @{kZEGO_TALK_USERID: [ZegoSettings sharedInstance].userID,
                               KZEGO_TALK_USERNAME: [ZegoSettings sharedInstance].userName};
    messageSendInfo[kZEGO_TALK_FROM_USER] = fromUser;
    
    //to user list
    NSMutableArray *toUserList = [NSMutableArray arrayWithCapacity:toUsers.count];
    for (ZegoUser *user in toUsers)
    {
        NSDictionary *toUser = @{kZEGO_TALK_USERID: user.userID,
                                 KZEGO_TALK_USERNAME: user.userName};
        [toUserList addObject:toUser];
    }
    messageSendInfo[kZEGO_TALK_TO_USER] = toUserList;
    
    //content
    messageSendInfo[kZEGO_TALK_CONTENT] = messageContent;
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:messageSendInfo options:0 error:&error];
    if (error)
    {
        NSLog(@"serialize json error %@", error);
        return nil;
    }
 
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (dataString.length == 0)
    {
        NSLog(@"NSData to NSString failed");
        return nil;
    }
    
    return dataString;
 }

+ (ZegoMessage *)createMessageFromDictionary:(NSDictionary *)dictionary
{
    NSString *command = dictionary[kZEGO_TALK_CMD];
    if (![command isEqualToString:kZEGO_MESSAGE_COMMAND])
        return nil;
    
    NSString *session = dictionary[kZEGO_MESSAGE_SESSION];
    if (session.length == 0)
        return nil;
    
    //添加发送方用户
    NSDictionary *fromDic = dictionary[kZEGO_TALK_FROM_USER];
    NSString *fromUserID = fromDic[kZEGO_TALK_USERID];
    NSString *fromUserName = fromDic[KZEGO_TALK_USERNAME];
    if (fromUserID.length == 0 || fromUserName.length == 0)
        return nil;
    
    NSMutableArray *memberList = [NSMutableArray array];
    for (NSDictionary *dic in dictionary[kZEGO_TALK_TO_USER])
    {
        NSString *userID = dic[kZEGO_TALK_USERID];
        NSString *userName = dic[KZEGO_TALK_USERNAME];
        if (userID.length == 0 || userName.length == 0)
            continue;
        
        ZegoUser *user = [ZegoUser new];
        user.userID = userID;
        user.userName = userName;
        
        [memberList addObject:user];
    }
    
    ZegoUser *fromUser = [ZegoUser new];
    fromUser.userID = fromUserID;
    fromUser.userName = fromUserName;
    [memberList addObject:fromUser];
    
    if (memberList.count < 2)
        return nil;
    
    ZegoMessage *message = [[ZegoMessage alloc] initWithSession:session memberList:memberList];
    [message onRecevieMessage:dictionary];
    
    return message;
}

- (void)onRecevieMessage:(NSDictionary *)messageReceiveInfo
{
    NSString *userIDKeyPath = [NSString stringWithFormat:@"%@.%@", kZEGO_TALK_FROM_USER, kZEGO_TALK_USERID];
    NSString *userID = [messageReceiveInfo valueForKeyPath:userIDKeyPath];
    NSString *userNameKeyPath = [NSString stringWithFormat:@"%@.%@", kZEGO_TALK_FROM_USER, KZEGO_TALK_USERNAME];
    NSString *userName = [messageReceiveInfo valueForKeyPath:userNameKeyPath];
    
    if (userID.length == 0 || userName.length == 0)
        return;
    
    NSString *content = messageReceiveInfo[kZEGO_TALK_CONTENT];
    if (content.length == 0)
        return;
    
    if (self.messageHistory == nil)
        self.messageHistory = [NSMutableArray array];
    
    ZegoUser *user = [ZegoUser new];
    user.userID = userID;
    user.userName = userName;
    
    ZegoMessageDetail *detail = [[ZegoMessageDetail alloc] initWithUser:user messageContent:content];
    [self.messageHistory addObject:detail];
}

- (void)setUnreadCount:(NSUInteger)unreadCount
{
    if (_unreadCount != unreadCount)
    {
        _unreadCount = unreadCount;
        
        //未读计数有变化，通知tabBarViewController
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserUnreadCountUpdateNotification object:nil userInfo:nil];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSMutableArray *memberList = [NSMutableArray arrayWithCapacity:self.memberList.count];
    for (ZegoUser *user in self.memberList)
    {
        ZegoMessageUser *messageUser = [ZegoMessageUser new];
        messageUser.userID = user.userID;
        messageUser.userName = user.userName;
        
        [memberList addObject:messageUser];
    }
    
    [aCoder encodeObject:self.session forKey:@"session"];
    [aCoder encodeObject:memberList forKey:@"memberList"];
    [aCoder encodeObject:self.messageHistory forKey:@"history"];
    [aCoder encodeInteger:self.unreadCount forKey:@"unreadCount"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.session = [aDecoder decodeObjectForKey:@"session"];
        NSArray *memberList = [aDecoder decodeObjectForKey:@"memberList"];
        self.memberList = [NSMutableArray arrayWithCapacity:memberList.count];
        for (ZegoMessageUser *messageUser in memberList)
        {
            ZegoUser *user = [ZegoUser new];
            user.userID = messageUser.userID;
            user.userName = messageUser.userName;
            
            [self.memberList addObject:user];
        }
        
        NSArray *messageHistory = [aDecoder decodeObjectForKey:@"history"];
        self.messageHistory = [NSMutableArray arrayWithArray:messageHistory];
        self.unreadCount = [aDecoder decodeIntegerForKey:@"unreadCount"];
    }
    
    return self;
}
@end
