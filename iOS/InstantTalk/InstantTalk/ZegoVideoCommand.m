//
//  ZegoVideoCommand.m
//  InstantTalk
//
//  Created by Strong on 16/7/11.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import "ZegoVideoCommand.h"
#import "ZegoSettings.h"

@implementation ZegoVideoRequestInfo

@end

@interface ZegoVideoCommand ()

@end

@implementation ZegoVideoCommand

+ (NSString *)formatVideoTalk:(NSString *)command toUserList:(NSArray<ZegoUser *> *)toUsers magicNumber:(NSString *)magicNumber agreed:(BOOL)agreed roomID:(unsigned int)roomID
{
    if (toUsers.count == 0 || magicNumber.length == 0)
        return nil;
    
    NSMutableDictionary *messageSendInfo = [NSMutableDictionary dictionary];
    messageSendInfo[kZEGO_TALK_CMD] = command;
    messageSendInfo[kZEGO_VIDEO_MAGIC] = magicNumber;
    
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
    
    if ([command isEqualToString:kZEGO_VIDEO_RESPOND_COMMAND])
    {
        NSString *content = kZEGO_VIDEO_AGREED;
        if (agreed == NO)
            content = kZEGO_VIDEO_DISAGREED;
        
        messageSendInfo[kZEGO_TALK_CONTENT] = content;
    }
    
    if (roomID != 0)
        messageSendInfo[kZEGO_VIDEO_ROOMID] = @(roomID);
    
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

+ (void)sendRequestVideoTalk:(NSArray<ZegoUser *> *)toUserList magicNumber:(NSString *)magicNumber preferedID:(unsigned int)roomID
{
    if (toUserList.count == 0 || magicNumber.length == 0)
        return;
    
    NSArray *notSelfMemberArray = [toUserList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userID != %@", [ZegoSettings sharedInstance].userID]];
    NSString *sendContent = [self formatVideoTalk:kZEGO_VIDEO_REQUEST_COMMAND toUserList:notSelfMemberArray magicNumber:magicNumber agreed:YES roomID:roomID];
    if (sendContent)
        [getBizRoomInstance() sendBroadcastTextMsgInChatRoom:sendContent isPublicRoom:YES];
}

+ (void)sendCancelVideoTalk:(NSArray<ZegoUser *> *)toUserList magicNumber:(NSString *)magicNumber
{
    if (toUserList.count == 0 || magicNumber.length == 0)
        return;
    
    NSArray *notSelfMemberArray = [toUserList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userID != %@", [ZegoSettings sharedInstance].userID]];
    NSString *sendContent = [self formatVideoTalk:kZEGO_VIDEO_CANCEL_COMMAND toUserList:notSelfMemberArray magicNumber:magicNumber agreed:NO roomID:0];
    if (sendContent)
        [getBizRoomInstance() sendBroadcastTextMsgInChatRoom:sendContent isPublicRoom:YES];
}

+ (void)sendRespondVideoTalk:(ZegoUser *)toUser magicNumber:(NSString *)magicNumber agreed:(BOOL)agreed preferedID:(unsigned int)roomID
{
    if (toUser == nil || magicNumber.length == 0)
        return;
    
    NSString *sendContent = [self formatVideoTalk:kZEGO_VIDEO_RESPOND_COMMAND toUserList:@[toUser] magicNumber:magicNumber agreed:agreed roomID:roomID];
    if (sendContent)
        [getBizRoomInstance() sendBroadcastTextMsgInChatRoom:sendContent isPublicRoom:YES];
}

+ (BOOL)agreedVideoTalk:(NSDictionary *)respondInfo expectMagicNumber:(NSString *)magicNumber expectedID:(unsigned int)roomID result:(BOOL *)result
{
    NSString *respondMagicNumber = respondInfo[kZEGO_VIDEO_MAGIC];
    if (![respondMagicNumber isEqualToString:magicNumber])
        return NO;
    
    unsigned int respondID = [respondInfo[kZEGO_VIDEO_ROOMID] unsignedIntValue];
    if (roomID != respondID)
        return NO;
    
    NSString *respondResult = respondInfo[kZEGO_TALK_CONTENT];
    if ([respondResult isEqualToString:kZEGO_VIDEO_AGREED])
    {
        *result = YES;
    }
    if ([respondResult isEqualToString:kZEGO_VIDEO_DISAGREED])
    {
        *result = NO;
    }
    
    return YES;
}

+ (ZegoVideoRequestInfo *)getRequestVideoTalkInfo:(NSDictionary *)requestInfo
{
    NSString *magicNumber = requestInfo[kZEGO_VIDEO_MAGIC];
    NSDictionary *fromDic = requestInfo[kZEGO_TALK_FROM_USER];
    NSString *fromUserID = fromDic[kZEGO_TALK_USERID];
    NSString *fromUserName = fromDic[KZEGO_TALK_USERNAME];
    unsigned int preferedID = [requestInfo[kZEGO_VIDEO_ROOMID] unsignedIntValue];
    
    if (magicNumber.length == 0 || fromUserID.length == 0 || fromUserName.length == 0)
        return nil;
    
    ZegoUser *fromUser = [ZegoUser new];
    fromUser.userID = fromUserID;
    fromUser.userName = fromUserName;
    
    ZegoVideoRequestInfo *info = [ZegoVideoRequestInfo new];
    info.fromUser = fromUser;
    info.magicNumber = magicNumber;
    info.preferedRoomID = preferedID;
    
    return info;
}

+ (NSString *)getCancelVideoTalkMagicNumber:(NSDictionary *)cancelInfo
{
    NSString *magicNumber = cancelInfo[kZEGO_VIDEO_MAGIC];
    if (magicNumber.length == 0)
        return nil;
    
    return magicNumber;
}

@end
