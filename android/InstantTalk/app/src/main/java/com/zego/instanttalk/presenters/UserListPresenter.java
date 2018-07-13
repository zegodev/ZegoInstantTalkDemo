package com.zego.instanttalk.presenters;

import android.os.Handler;

import com.zego.biz.BizUser;
import com.zego.instanttalk.interfaces.UserListView;
import com.zego.instanttalk.utils.PreferenceUtil;

import java.util.ArrayList;
import java.util.List;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public class UserListPresenter {

    private static UserListPresenter sInstance;

    private List<BizUser> mListUser;

    private UserListView mUserListView;

    private Handler mUIHandler;

    private UserListPresenter() {
        mListUser = new ArrayList<>();
    }

    public static UserListPresenter getInstance(){
        if(sInstance == null){
            synchronized (UserListPresenter.class){
                if(sInstance == null){
                    sInstance = new UserListPresenter();
                }
            }
        }
        return sInstance;
    }

    public void setUserListView(UserListView userListView, Handler handler){
        mUserListView = userListView;
        mUIHandler = handler;

        if(mUserListView != null && mUIHandler != null){
            if(mUIHandler != null && mUserListView != null){
                mUIHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        mUserListView.onUserListUpdate(mListUser);
                    }
                });
            }
        }
    }


    public void updateUserList(BizUser[] bizUsers, int flag){
        if (bizUsers == null || bizUsers.length == 0) {
            return;
        }

        // 全量更新, 清除本地数据
        if (flag == 1) {
            mListUser.clear();
        }

        for (BizUser user : bizUsers) {
            int updateFlag = user.updateFlag;
            String userID = user.userID;

            // 1:add 2:delete 3:update
            if (updateFlag == 2) {
                removeUser(userID);
            } else {
                if (isSelf(userID)) {
                    continue;
                }
                // 如果本地已经存在该用户信息,先移除
                removeUser(userID);

                mListUser.add(user);
            }
        }

        if(mUIHandler != null && mUserListView != null){
            mUIHandler.post(new Runnable() {
                @Override
                public void run() {
                    mUserListView.onUserListUpdate(mListUser);
                }
            });
        }
    }


    private boolean isSelf(String userID){
        boolean isSelf = false;

        if(PreferenceUtil.getInstance().getUserID().equals(userID)){
            isSelf = true;
        }

        return isSelf;
    }

    private void removeUser(String userID){
        for(BizUser bizUser : mListUser){
            if(bizUser.userID.equals(userID)){
                mListUser.remove(bizUser);
                break;
            }
        }
    }

    public List<BizUser> getUserList(){
        return mListUser;
    }

    public void clearUserList(){
        mListUser.clear();
    }
}
