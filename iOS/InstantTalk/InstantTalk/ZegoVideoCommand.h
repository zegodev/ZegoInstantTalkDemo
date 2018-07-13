//
//  ZegoVideoCommand.h
//  InstantTalk
//
//  Created by Strong on 16/7/11.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZegoAVKitManager.h"
#import "ZegoCommand.h"

@interface ZegoVideoRequestInfo : NSObject

@property (nonatomic, strong) ZegoUser *fromUser;
@property (nonatomic, copy) NSString *magicNumber;
@property (nonatomic, assign) unsigned int preferedRoomID;

@end

@interface ZegoVideoCommand : NSObject

+ (void)sendRequestVideoTalk:(NSArray<ZegoUser*> *)toUserList magicNumber:(NSString *)magicNumber preferedID:(unsigned int)roomID;
+ (ZegoVideoRequestInfo *)getRequestVideoTalkInfo:(NSDictionary *)requestInfo;

+ (BOOL)agreedVideoTalk:(NSDictionary *)respondInfo expectMagicNumber:(NSString *)magicNumber expectedID:(unsigned int)roomID result:(BOOL *)result;
+ (void)sendRespondVideoTalk:(ZegoUser *)toUser magicNumber:(NSString *)magicNumber agreed:(BOOL)agreed preferedID:(unsigned int)roomID;

+ (void)sendCancelVideoTalk:(NSArray<ZegoUser *> *)toUserList magicNumber:(NSString *)magicNumber;
+ (NSString *)getCancelVideoTalkMagicNumber:(NSDictionary *)cancelInfo;

@end
