package com.zego.instanttalk.interfaces;

import com.zego.instanttalk.entities.ChatMsg;

import java.util.List;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public interface OnUpdateMsgListListener{
        void onShowAllMsg(String session, List<ChatMsg> listMsg);
}
