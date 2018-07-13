package com.zego.instanttalk.interfaces;

import com.zego.biz.BizUser;

import java.util.List;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */
public interface OnPublicRoomListener {

    void onLoginSuccessfully(long roomKey, long serverKey);

    void onLoginFailed(int errCode, long roomKey, long serverKey);

    void onLeaveRoom(int errCode);

    void onCancelChat();

    void onDisconnected(int errCode, long roomKey, long serverKey);

    void onShowRequestMsg(List<BizUser> listToUser, String magic, long roomKey, String fromUserName);
}
