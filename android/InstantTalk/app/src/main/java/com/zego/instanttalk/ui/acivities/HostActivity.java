package com.zego.instanttalk.ui.acivities;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import com.zego.biz.BizUser;
import com.zego.instanttalk.R;
import com.zego.instanttalk.constants.IntentExtra;
import com.zego.instanttalk.presenters.BizLivePresenter;

import java.util.ArrayList;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */
public class HostActivity extends BaseVideoChatActivity {

    protected boolean mHaveTriedToLoginPrivateRoom = false;

    protected int mRefusedCount = 0;

    /**
     * 启动入口.
     *
     * @param activity 源activity
     */
    public static void actionStart(Activity activity, ArrayList<BizUser> listToUser) {
        Intent intent = new Intent(activity, HostActivity.class);
        intent.putParcelableArrayListExtra(IntentExtra.TO_USERS, listToUser);
        activity.startActivity(intent);
    }


    @Override
    protected void doBusiness(Bundle savedInstanceState) {
        super.doBusiness(savedInstanceState);

        if (savedInstanceState == null) {
            // 发送视频聊天请求
            BizLivePresenter.getInstance().requestVideoChat(mListToUser);
            showMainMsg(getString(R.string.waiting_for_response));
            printLog(getString(R.string.myself, getString(R.string.waiting_for_response)));
        }
    }



    @Override
    protected void handleRespondMsg(boolean isRespondToMyRequest, long roomKey, boolean isAgreed, String fromUserName) {
        if (isRespondToMyRequest) {
            if (isAgreed) {
                // 有人答应视频聊天,退出大厅房间
                mRoomKey = roomKey;

                showSubMsg(getString(R.string.someone_accepted_your_request, fromUserName));
                printLog(getString(R.string.someone_accepted_your_request, fromUserName));

                if (!mHaveTriedToLoginPrivateRoom) {
                    mHaveTriedToLoginPrivateRoom = true;

                    // 登陆私有房间
                    BizLivePresenter.getInstance().loginPrivateRoom(mRoomKey);
                    showMainMsg(getString(R.string.start_to_login_private_room));
                    printLog(getString(R.string.myself, getString(R.string.start_to_login_private_room_log, mRoomKey + "")));
                }

            } else {
                showSubMsg(getString(R.string.someone_refused_your_request, fromUserName));
                printLog(getString(R.string.someone_refused_your_request, fromUserName));

                mRefusedCount++;
                if (mRefusedCount == mListToUser.size()) {
                    showMainMsg(getString(R.string.chat_finished));
                    showSubMsg(getString(R.string.all_friends_refused_your_request));
                    printLog(getString(R.string.myself, getString(R.string.all_friends_refused_your_request)));
                }
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // 发送"取消视频聊天"消息
        BizLivePresenter.getInstance().cancelVideoChat(mListToUser, mRoomKey);
    }
}
