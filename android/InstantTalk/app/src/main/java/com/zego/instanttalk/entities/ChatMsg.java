package com.zego.instanttalk.entities;

import java.io.Serializable;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public class ChatMsg implements Serializable{

    public static final int VALUE_LEFT_TEXT = 1;
    public static final int VALUE_RIGHT_TEXT = 2;

    private int mType;
    private String mContent;
    private String mFromUserID;
    private String mFromUserName;
    private String mSession;

    public String getContent() {
        return mContent;
    }

    public void setContent(String content) {
        mContent = content;
    }

    public String getFromUserID() {
        return mFromUserID;
    }

    public void setFromUserID(String fromUserID) {
        mFromUserID = fromUserID;
    }

    public String getFromUserName() {
        return mFromUserName;
    }

    public void setFromUserName(String fromUserName) {
        mFromUserName = fromUserName;
    }

    public String getSession() {
        return mSession;
    }

    public void setSession(String session) {
        mSession = session;
    }

    public int getType() {
        return mType;
    }

    public void setType(int type) {
        mType = type;
    }

}
