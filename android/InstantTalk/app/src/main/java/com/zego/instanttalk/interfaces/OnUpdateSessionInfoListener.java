package com.zego.instanttalk.interfaces;

import com.zego.instanttalk.entities.SessionInfo;

import java.util.LinkedList;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public interface OnUpdateSessionInfoListener {
    void onUpdateSessionInfo(LinkedList<SessionInfo> listSessionInfo, int unreadMsgTotalCount);
    void onNotifyMsgComing(String fromUserName);
}
