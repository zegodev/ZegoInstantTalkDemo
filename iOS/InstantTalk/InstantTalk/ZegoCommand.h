//
//  ZegoCommand.h
//  InstantTalk
//
//  Created by Strong on 16/7/12.
//  Copyright © 2016年 ZEGO. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kZEGO_TALK_CMD;
extern NSString *const kZEGO_TALK_FROM_USER;
extern NSString *const kZEGO_TALK_USERID;
extern NSString *const KZEGO_TALK_USERNAME;
extern NSString *const kZEGO_TALK_TO_USER;
extern NSString *const kZEGO_TALK_CONTENT;

//message
extern NSString *const kZEGO_MESSAGE_COMMAND;
extern NSString *const kZEGO_MESSAGE_SESSION;

//video
extern NSString *const kZEGO_VIDEO_REQUEST_COMMAND;
extern NSString *const kZEGO_VIDEO_RESPOND_COMMAND;
extern NSString *const kZEGO_VIDEO_CANCEL_COMMAND;

extern NSString *const kZEGO_VIDEO_MAGIC;
extern NSString *const kZEGO_VIDEO_ROOMID;
extern NSString *const kZEGO_VIDEO_AGREED;
extern NSString *const kZEGO_VIDEO_DISAGREED;

@interface ZegoCommand : NSObject

@end
