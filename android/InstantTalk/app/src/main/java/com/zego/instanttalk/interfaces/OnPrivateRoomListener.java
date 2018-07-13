package com.zego.instanttalk.interfaces;

import com.zego.biz.BizStream;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */
public interface OnPrivateRoomListener {

    void onLoginSuccessfully(long roomKey, long serverKey);

    void onLoginFailed(int errCode, long roomKey, long serverKey);

    void onLeaveRoom(int errCode);

    void onDisconnected(int errCode, long roomKey, long serverKey);

    void onStreamCreate(String streamID, String url);

    void onStreamAdd(BizStream[] bizStreams);

    void onStreamDelete(BizStream[] bizStreams);

    void onShowRespondMsg(boolean isRespondToMyRequest, long roomKey, boolean isAgreed, String fromUserName);
}
