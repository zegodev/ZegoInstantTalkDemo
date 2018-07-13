package com.zego.instanttalk.entities;

import com.zego.biz.BizUser;

import java.io.Serializable;
import java.util.List;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public class SessionInfo implements Serializable {

    private String mNewestContent;

    private String mFromUserID;

    private String mFromUserName;

    private String mSession;

    private long mCreatedTime;

    private int mUnreadMsgCount;

    private List<BizUser> mListUser;

    public long getCreatedTime() {
        return mCreatedTime;
    }

    public void setCreatedTime(long createdTime) {
        mCreatedTime = createdTime;
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

    public String getNewestContent() {
        return mNewestContent;
    }

    public void setNewestContent(String newestContent) {
        mNewestContent = newestContent;
    }

    public String getSession() {
        return mSession;
    }

    public void setSession(String session) {
        mSession = session;
    }

    public int getUnreadMsgCount() {
        return mUnreadMsgCount;
    }

    public void setUnreadMsgCount(int unreadMsgCount) {
        mUnreadMsgCount = unreadMsgCount;
    }

    public List<BizUser> getListUser() {
        return mListUser;
    }

    public void setListUser(List<BizUser> listUser) {
        mListUser = listUser;
    }
}
