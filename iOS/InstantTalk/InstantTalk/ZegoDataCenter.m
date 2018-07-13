//
//  ZegoDataCenter.m
//  InstantTalk
//
//  Created by Strong on 16/7/7.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import "ZegoDataCenter.h"
#import "ZegoSettings.h"
#import "ZegoAVKitManager.h"
#import "ZegoMessage.h"
#import "ZegoVideoCommand.h"

#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>

NSString *const kUserUpdateNotification             = @"userUpdate";
NSString *const kUserLoginNotification              = @"userLogin";
NSString *const kUserDisconnectNotification         = @"userDisconnect";
NSString *const kUserMessageReceiveNotification     = @"receiveMessage";
NSString *const kUserMessageSendNotification        = @"sendMessage";
NSString *const kUserRequestVideoTalkNotification   = @"requestVideoTalk";
NSString *const kUserAcceptVideoTalkNotification    = @"acceptVideoTalk";
NSString *const kUserLeaveRoomNotification          = @"leaveRoom";
NSString *const kUserRespondVideoTalkNotification   = @"respondVideoTalk";
NSString *const kUserCancelVideoTalkNotification    = @"cancelVideoTalk";
NSString *const kUserClearAllSessionNotification   = @"clearAllSession";
//NSString *const kUserRequestWhileTalkingNotification = @"requestWileTalking";

@implementation ZegoUserInfo

@end

@interface ZegoDataCenter () <BizRoomStreamDelegate>
//日志记录
@property (nonatomic, strong) NSMutableArray *logArray;

@property (nonatomic, copy) NSString *magicNumber;
@property (nonatomic, assign) unsigned int preferedID;

//接收到的请求视频列表
@property (nonatomic, strong) NSMutableDictionary<NSString*, ZegoVideoRequestInfo*> *receivedRequestList;

@property (nonatomic, weak) id<BizRoomStreamDelegate> privateDelegate;

@end

@implementation ZegoDataCenter

+ (instancetype)sharedInstance
{
    static ZegoDataCenter *gInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gInstance = [[ZegoDataCenter alloc] init];
    });
    
    return gInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.logArray = [NSMutableArray array];
        _userList = [[NSMutableArray alloc] init];
        self.receivedRequestList = [NSMutableDictionary dictionary];
        
        [self loadSessionList];
        if (_sessionList == nil)
            _sessionList = [[NSMutableArray alloc] init];
        
        [self setStreamDelegate];
        _isLogin = NO;
    }
    
    return self;
}

- (void)setStreamDelegate
{
    getBizRoomInstance().streamDelegate = self;
}

- (void)registerPrivateRoomDelegate:(id<BizRoomStreamDelegate>)privateDelegate
{
    self.privateDelegate = privateDelegate;
}

- (NSString *)getCurrentTime
{
//    return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"[HH-mm-ss:SSS]";
    return [formatter stringFromDate:[NSDate date]];
}

- (void)addLogString:(NSString *)logString
{
    if (logString.length != 0)
    {
        NSString *totalString = [NSString stringWithFormat:@"%@: %@", [self getCurrentTime], logString];
        [self.logArray insertObject:totalString atIndex:0];
    }
}

- (void)onLeavePrivateRoom:(NSNotification *)notification
{
    [self setStreamDelegate];
    [self loginRoom];
}

- (void)loginRoom
{
    if (self.isLogin)
    {
        [self addLogString:NSLocalizedString(@"当前已登录", nil)];
        return;
    }
    
    ZegoUser *user = [[ZegoSettings sharedInstance] getZegoUser];
    [getBizRoomInstance() loginLiveRoom:user.userID userName:user.userName bizToken:0 bizID:[ZegoSettings sharedInstance].bizID isPublicRoom:YES];
    
    [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"开始登录房间", nil)]];
}

- (void)leaveRoom
{
    if (!self.isLogin)
    {
        [self addLogString:NSLocalizedString(@"当前未登录或进入了私聊房间", nil)];
        return;
    }
    
    [getBizRoomInstance() leaveLiveRoom:YES];
    
    [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"离开房间", nil)]];
}

#pragma mark BizStreamDelegate
- (void)onLoginRoom:(int)err bizID:(unsigned int)bizID bizToken:(unsigned int)bizToken isPublicRoom:(bool)isPublicRoom
{
    NSLog(@"%s, error: %d, isPublicRoom:%d", __func__, err, isPublicRoom);
    
    if (isPublicRoom == NO)
    {
        if ([self.privateDelegate respondsToSelector:@selector(onLoginRoom:bizID:bizToken:isPublicRoom:)])
            [self.privateDelegate onLoginRoom:err bizID:bizID bizToken:bizToken isPublicRoom:isPublicRoom];
        
        return;
    }
    
    if (err == 0)
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"登录房间成功. token %d, id %d", nil), bizToken, bizID];
        [self addLogString:logString];
        
        _isLogin = YES;
    }
    else
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"登录房间失败. error: %d", nil), err];
        [self addLogString:logString];
        
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoginNotification object:nil userInfo:@{@"Result": @(self.isLogin)}];
}

- (void)onLeaveRoom:(int)err isPublicRoom:(bool)isPublicRoom
{
    if (isPublicRoom == NO)
    {
        if ([self.privateDelegate respondsToSelector:@selector(onLeaveRoom:isPublicRoom:)])
            [self.privateDelegate onLeaveRoom:err isPublicRoom:isPublicRoom];
        return;
    }
    
    [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"离开房间结果. error: %d", nil), err]];
    _isLogin = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLeaveRoomNotification object:nil userInfo:nil];
}

- (void)onDisconnected:(int)err bizID:(unsigned int)bizID bizToken:(unsigned int)bizToken isPublicRoom:(bool)isPublicRoom
{
    NSLog(@"%s, error: %d", __func__, err);
    
    if (isPublicRoom == NO)
    {
        if ([self.privateDelegate respondsToSelector:@selector(onDisconnected:bizID:bizToken:isPublicRoom:)])
            [self.privateDelegate onDisconnected:err bizID:bizID bizToken:bizToken isPublicRoom:isPublicRoom];
        
        return;
    }
    
    if (err == 0)
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"断开房间. token %d, id %d", nil), bizToken, bizID];
        [self addLogString:logString];
    }
    else
    {
        NSString *logString = [NSString stringWithFormat:NSLocalizedString(@"断开房间. error: %d", nil), err];
        [self addLogString:logString];
    }
    
    _isLogin = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserDisconnectNotification object:self userInfo:nil];
    
}

- (BOOL)isUserSelf:(NSString *)userID
{
    if ([[ZegoSettings sharedInstance].userID isEqualToString:userID])
        return YES;
    
    return NO;
}

//flag = 1 全量
//flag = 2 增量
- (BOOL)isUserExist:(NSString *)userID
{
    NSArray *filterArray = [self.userList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"user.userID == %@", userID]];
    if (filterArray.count == 0)
        return NO;
    
    return YES;
}

- (void)removeUser:(NSString *)userID
{
    NSArray *filterArray = [self.userList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"user.userID == %@", userID]];
    if (filterArray.count == 0)
        return;
    
    [self.userList removeObjectsInArray:filterArray];
}

- (void)onRoomUserUpdate:(NSArray<NSDictionary *> *)userInfoList flag:(int)flag isPublicRoom:(bool)isPublicRoom
{
    if (isPublicRoom == NO)
    {
        if ([self.privateDelegate respondsToSelector:@selector(onRoomUserUpdate:flag:isPublicRoom:)])
            [self.privateDelegate onRoomUserUpdate:userInfoList flag:flag isPublicRoom:isPublicRoom];
        
        return;
    }
    
    //for test
    if (flag == 1)
        [self.userList removeAllObjects];
    
    for (NSDictionary *dict in userInfoList)
    {
        unsigned int userFlage = [dict[kUserInfoUpdateKey] unsignedIntValue];
        unsigned int dwIndex =[dict[kUserInfoIndexKey] unsignedIntValue];
        NSString *userID = dict[kUserInfoUserIDKey];
        NSString *userName = dict[kUserInfoUserNameKey];
        
        //userFlage = 1 (ADDED) 3(UPDATED)
        if (userFlage != 2)
        {
            NSLog(@"%s, add new userID %@, userName %@", __func__, userID, userName);
            
            if ([self isUserSelf:userID])
            {
                NSLog(@"%s, user is self, userID %@", __func__, userID);
                continue;
            }
            
            if ([self isUserExist:userID])
            {
                NSLog(@"%s, user exist userID %@", __func__, userID);
                
                NSArray *filterArray = [self.userList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"user.userID == %@", userID]];
                [self.userList removeObjectsInArray:filterArray];
            }
            
            ZegoUser *user = [ZegoUser new];
            user.userName = userName;
            user.userID = userID;
            
            ZegoUserInfo *userInfo = [ZegoUserInfo new];
            userInfo.userIndex = dwIndex;
            userInfo.user = user;
            
            [self.userList addObject:userInfo];
        }
        else
        {
            NSLog(@"%s, remove userID %@", __func__, userID);
            
            [self removeUser:userID];
        }
    }
    
    //通知界面更新
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserUpdateNotification object:self userInfo:nil];
}

- (void)onReceiveMessage:(NSData *)content messageType:(int)type isPublicRoom:(bool)isPublicRoom
{
    if (isPublicRoom == NO)
    {
        if ([self.privateDelegate respondsToSelector:@selector(onReceiveMessage:messageType:isPublicRoom:)])
            [self.privateDelegate onReceiveMessage:content messageType:type isPublicRoom:isPublicRoom];
        
        return;
    }
    
    //收到text消息
    if (type == 1)
    {
        NSError *error;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:content options:0 error:&error];
        if (error)
        {
            NSLog(@"JSONObjectWithData error");
            return;
        }
        
        if (![self messageShouldReceive:dictionary])
            return;
        
        //get command
        NSString *command = dictionary[kZEGO_TALK_CMD];
        if ([command isEqualToString:kZEGO_MESSAGE_COMMAND])
        {
            [self onReceiveChatMessage:dictionary];
        }
        else if ([command isEqualToString:kZEGO_VIDEO_REQUEST_COMMAND])
        {
            [self onReceiveVideoRequestMessage:dictionary];
        }
        else if ([command isEqualToString:kZEGO_VIDEO_RESPOND_COMMAND])
        {
            [self onReceiveVideoRespondMessage:dictionary];
        }
        else if ([command isEqualToString:kZEGO_VIDEO_CANCEL_COMMAND])
        {
            [self onReceiveVideoCancelMessage:dictionary];
        }
    }
}

- (void)onStreamCreate:(NSString *)streamID url:(NSString *)url isPublicRoom:(bool)isPublicRoom
{
    if (isPublicRoom == NO)
    {
        if ([self.privateDelegate respondsToSelector:@selector(onStreamCreate:url:isPublicRoom:)])
            [self.privateDelegate onStreamCreate:streamID url:url isPublicRoom:isPublicRoom];
    }
}

- (void)onStreamUpdate:(NSArray<NSDictionary *> *)streamList flag:(int)flag isPublicRoom:(bool)isPublicRoom
{
    if (isPublicRoom == NO)
    {
        if ([self.privateDelegate respondsToSelector:@selector(onStreamUpdate:flag:isPublicRoom:)])
            [self.privateDelegate onStreamUpdate:streamList flag:flag isPublicRoom:isPublicRoom];
        else
            NSLog(@"private delegate is nill");
    }
}

- (void)updateMessageIndex:(ZegoMessage *)message
{
    if (message == nil)
        return;
    
    [self.sessionList removeObject:message];
    [self.sessionList insertObject:message atIndex:0];
}

- (ZegoMessage *)getMessageFromSessionID:(NSString *)session
{
    if (session.length == 0)
        return nil;
    
    NSArray *filterArray = [self.sessionList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"session == %@", session]];
    if (filterArray.count != 1)
        return nil;
    
    return [filterArray firstObject];
}

- (BOOL)messageShouldReceive:(NSDictionary *)messageReceiveInfo
{
    NSArray *toUserList = messageReceiveInfo[kZEGO_TALK_TO_USER];
    if (toUserList.count == 0)
        return NO;
    
    for (NSDictionary *dict in toUserList)
    {
        if ([dict[kZEGO_TALK_USERID] isEqualToString:[ZegoSettings sharedInstance].userID])
            return YES;
    }
    
    return NO;
}

- (ZegoMessage *)messageExistWithDifferentSession:(NSDictionary *)messageReceiveInfo
{
    NSArray *toUserList = messageReceiveInfo[kZEGO_TALK_TO_USER];
    if (toUserList.count != 1)
        return nil;
    
    NSDictionary *fromUserInfo = messageReceiveInfo[kZEGO_TALK_FROM_USER];
    NSString *userID = fromUserInfo[kZEGO_TALK_USERID];
    
    /*
    NSDictionary *dictionary = [toUserList firstObject];
    NSString *userID = dictionary[kZEGO_TALK_USERID];
     */
    NSString *session = [self getSessionID:userID];
    if (session)
    {
        return [self getMessageFromSessionID:session];
    }
    return nil;
}

- (void)onReceiveChatMessage:(NSDictionary *)messageReceiveInfo
{
    NSString *sessionID = messageReceiveInfo[kZEGO_MESSAGE_SESSION];
    if (sessionID.length == 0)
        return;
    
    ZegoMessage *message = [self getMessageFromSessionID:sessionID];
    if (message)
    {
        [message onRecevieMessage:messageReceiveInfo];
        [self updateMessageIndex:message];
    }
    else
    {
        //如果是单人会话，检查已有会话列表中是否已存在，只是session不同
        ZegoMessage *oldMessage = [self messageExistWithDifferentSession:messageReceiveInfo];
        if (oldMessage)
        {
//            [self.sessionList removeObject:oldMessage];
            oldMessage.session = sessionID;
            [oldMessage onRecevieMessage:messageReceiveInfo];
            [self updateMessageIndex:oldMessage];
        }
        else
        {
            //create new session
            message = [ZegoMessage createMessageFromDictionary:messageReceiveInfo];
            if (message == nil)
                return;
            [self.sessionList insertObject:message atIndex:0];
        }
    }
    
    //消息未读计数+1
    message.unreadCount += 1;
    //通知界面收到message
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserMessageReceiveNotification object:nil userInfo:@{@"session": sessionID}];
}

- (BOOL)isMemberListContainSelf:(NSArray<ZegoUser *> *)memberList
{
    NSArray *filterArray = [memberList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userID == %@", [ZegoSettings sharedInstance].userID]];
    if (filterArray.count == 1)
        return YES;
    
    return NO;
}

- (ZegoUser *)getOtherUser:(NSArray<ZegoUser *> *)memberList
{
    if (memberList.count != 2)
        return nil;
    
    NSArray *notSelfMemberArray = [memberList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userID != %@", [ZegoSettings sharedInstance].userID]];
    if (notSelfMemberArray.count != 1)
        return nil;
    
    return notSelfMemberArray.firstObject;
}

- (NSString *)getSessionID:(NSString *)userID
{
    if (userID.length == 0)
        return nil;
    
    for (ZegoMessage *message in self.sessionList)
    {
        if (message.memberList.count != 2)
            continue;
        
        ZegoUser *otherUser = [self getOtherUser:message.memberList];
        if ([otherUser.userID isEqualToString:userID])
            return message.session;
    }
    
    return nil;
}

- (NSString *)createSessionWithMemberList:(NSArray<ZegoUser *> *)memberList;
{
    if (memberList.count < 2)
        return nil;
    
    //检查memberlist是否有创建者
    if (![self isMemberListContainSelf:memberList])
    {
        NSLog(@"memberlist dont have self");
        return nil;
    }
    
    //检查session是否存在
    if (memberList.count == 2)
    {
        NSString *sessionID = [self getSessionID:[self getOtherUser:memberList].userID];
        if (sessionID.length != 0)
            return sessionID;
    }
    
    NSString *sessionID = [NSString stringWithFormat:@"%@+%lu", [ZegoSettings sharedInstance].userID, (NSUInteger)[[NSDate date] timeIntervalSince1970]];
    
    //初始化session
    ZegoMessage *newMessage = [[ZegoMessage alloc] initWithSession:sessionID memberList:memberList];
    [self.sessionList insertObject:newMessage atIndex:0];
    
    return sessionID;
}

- (void)addMember:(NSArray<ZegoUser *> *)addMemberList sessionID:(NSString *)sessionID
{
    if (sessionID.length == 0 || addMemberList.count == 0)
        return;
    
    ZegoMessage *message = [self getMessageFromSessionID:sessionID];
    if (message == nil)
        return;
    
    [message addMemberList:addMemberList];
}

- (void)sendMessage:(NSString *)sessionID messageContent:(NSString *)messageContent
{
    if (sessionID.length == 0 || messageContent.length == 0)
        return;
    
    ZegoMessage *message = [self getMessageFromSessionID:sessionID];
    if (message == nil)
        return;
    
    [message sendMessage:messageContent];
    [self updateMessageIndex:message];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserMessageSendNotification object:nil];
}

- (NSArray<ZegoUser *> *)getMemberList:(NSString *)sessionID
{
    if (sessionID.length == 0)
        return nil;
    
    ZegoMessage *message = [self getMessageFromSessionID:sessionID];
    if (message == nil)
        return nil;
    
    return message.memberList;
}

- (NSArray<ZegoMessageDetail*> *)getMessageList:(NSString *)sessionID
{
    if (sessionID.length == 0)
        return nil;
    
    ZegoMessage *message = [self getMessageFromSessionID:sessionID];
    if (message == nil)
        return nil;
    
    return message.messageHistory;
}

- (ZegoMessage *)getMessageInfo:(NSString *)sessionID
{
    if (sessionID.length == 0)
        return nil;
    
    ZegoMessage *message = [self getMessageFromSessionID:sessionID];
    
    return message;
}

- (void)clearUnreadCount:(NSString *)sessionID
{
    ZegoMessage *message = [self getMessageFromSessionID:sessionID];
    if (message == nil)
        return;
    
    message.unreadCount = 0;
}

- (NSUInteger)getTotalUnreadCount
{
    NSUInteger totalCount = 0;
    for (ZegoMessage *messge in self.sessionList)
    {
        totalCount += messge.unreadCount;
    }
    
    return totalCount;
}

- (void)deleteMessageHistory:(ZegoMessage *)message
{
    if (message == nil)
        return;
    
    if (message.unreadCount != 0)
    {
        message.unreadCount = 0;
    }
    
    [self.sessionList removeObject:message];
    
}

- (void)clearAllSession
{
    [self.sessionList removeAllObjects];
    [self saveSessionList];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserClearAllSessionNotification object:nil userInfo:nil];
}

- (NSString *)documentPath
{
    NSArray *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [documents firstObject];
}

- (void)saveSessionList
{
    NSString *sessionListPath = [[self documentPath] stringByAppendingPathComponent:@"session"];
    [NSKeyedArchiver archiveRootObject:self.sessionList toFile:sessionListPath];
}

- (void)loadSessionList
{
    NSString *sessionListPath = [[self documentPath] stringByAppendingPathComponent:@"session"];
    NSArray *sessionList = [NSKeyedUnarchiver unarchiveObjectWithFile:sessionListPath];
    
    _sessionList = [NSMutableArray arrayWithArray:sessionList];
}

- (BOOL)isUserOnline:(NSString *)userID
{
    NSArray *filterArray = [self.userList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"user.userID == %@", userID]];
    if (filterArray.count > 0)
        return YES;
    
    return NO;
}

- (BOOL)isMemberOnline:(NSArray<ZegoUser *> *)userList
{
    if (!self.isLogin)
        return NO;
    
    NSArray *filterArray = [userList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userID != %@", [ZegoSettings sharedInstance].userID]];
    if (filterArray.count == 0)
        return NO;
    
    for (ZegoUser *user in filterArray)
    {
        if ([self isUserOnline:user.userID])
            return YES;
    }
    
    return NO;
}

- (void)requestVideoTalk:(NSArray<ZegoUser *> *)userList
{
    unsigned int token = [[ZegoSettings sharedInstance].userID intValue];
    if (token == 0 || token == 1)
        token = rand() + token;
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    self.magicNumber = [NSString stringWithFormat:@"%d", token];
    unsigned int below = (unsigned int)currentTime & 0xFFFF;
    unsigned int high = (unsigned int)((token << 16) & 0xFFFFF0000);
    
    //约定的房间ID 低16位(当前时间低16位） 高16位（token低16位）
    self.preferedID = high | below;
    
    [ZegoVideoCommand sendRequestVideoTalk:userList magicNumber:self.magicNumber preferedID:self.preferedID];
}

- (void)cancelVideoTalk:(NSArray<ZegoUser *> *)userList
{
    if (self.magicNumber.length != 0)
        [ZegoVideoCommand sendCancelVideoTalk:userList magicNumber:self.magicNumber];
}

- (void)onReceiveVideoRequestMessage:(NSDictionary *)receiveInfo
{
    ZegoVideoRequestInfo *info = [ZegoVideoCommand getRequestVideoTalkInfo:receiveInfo];
    
    //用户正作为发起方，等待别人同意通话，此时拒绝所有其他请求
    NSDictionary *userInfo = nil;
    if (self.magicNumber != nil)
    {
        userInfo = @{@"requestInfo": info, @"isTalking": @(YES)};
    }
    else
    {
        userInfo = @{@"requestInfo": info, @"isTalking": @(NO)};
    }
    
    //通知界面显示弹框，保存中间信息
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserRequestVideoTalkNotification object:nil userInfo:userInfo];
    self.receivedRequestList[info.magicNumber] = info;
}

- (void)onReceiveVideoRespondMessage:(NSDictionary *)receiveInfo
{
    BOOL agreed = NO;
    BOOL respondResult = [ZegoVideoCommand agreedVideoTalk:receiveInfo expectMagicNumber:self.magicNumber expectedID:self.preferedID result:&agreed];
    if (respondResult)
    {
        //有用户回复了视频聊天，通知界面
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserRespondVideoTalkNotification object:nil userInfo:@{@"result": @(agreed), @"roomID": @(self.preferedID)}];
    }
}

- (void)onReceiveVideoCancelMessage:(NSDictionary *)receiveInfo
{
    NSString *magicNumber = [ZegoVideoCommand getCancelVideoTalkMagicNumber:receiveInfo];
    if (magicNumber.length != 0)
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserCancelVideoTalkNotification object:nil userInfo:@{@"magicNumber": magicNumber}];
}

- (void)agreedVideoTalk:(BOOL)agreed magicNumber:(NSString *)magicNumber
{
    ZegoVideoRequestInfo *requestInfo = self.receivedRequestList[magicNumber];
    if (requestInfo == nil)
        return;
    
    [ZegoVideoCommand sendRespondVideoTalk:requestInfo.fromUser magicNumber:requestInfo.magicNumber agreed:agreed preferedID:requestInfo.preferedRoomID];
    //用户已选择，删除信息
    [self.receivedRequestList removeObjectForKey:requestInfo.magicNumber];
    
    if (agreed)
    {
        //如果同意，通知上层界面进入token定义的房间
        self.magicNumber = magicNumber;
        self.preferedID = requestInfo.preferedRoomID;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserAcceptVideoTalkNotification object:nil userInfo:@{@"roomID": @(requestInfo.preferedRoomID)}];
    }
}

- (void)stopVideoTalk
{
    self.magicNumber = nil;
    self.preferedID = 0;
}

- (void)contactUs
{
#if defined(__i386__)
#else
    if (![QQApiInterface isQQInstalled])
    {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"联系我们", nil)];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"没有安装QQ", nil) message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        
        return;
    }
    
    QQApiWPAObject *wpaObject = [QQApiWPAObject objectWithUin:@"84328558"];
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:wpaObject];
    QQApiSendResultCode result = [QQApiInterface sendReq:req];
    NSLog(@"share result %d", result);
#endif
}
@end
