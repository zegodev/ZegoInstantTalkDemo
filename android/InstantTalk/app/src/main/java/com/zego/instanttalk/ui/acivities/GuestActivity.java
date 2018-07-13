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
public class GuestActivity extends BaseVideoChatActivity {

    /**
     * 启动入口.
     *
     * @param activity 源activity
     */
    public static void actionStart(Activity activity, ArrayList<BizUser> listToUser, long roomKey) {
        Intent intent = new Intent(activity, GuestActivity.class);
        intent.putParcelableArrayListExtra(IntentExtra.TO_USERS, listToUser);
        intent.putExtra(IntentExtra.ROOM_KEY, roomKey);
        activity.startActivity(intent);
    }

    @Override
    protected void initExtraData(Bundle savedInstanceState) {
        super.initExtraData(savedInstanceState);
        if (savedInstanceState == null) {
            mRoomKey = getIntent().getLongExtra(IntentExtra.ROOM_KEY, 0);
            if(mRoomKey == 0){
                finish();
            }
        }
    }

    @Override
    protected void doBusiness(Bundle savedInstanceState) {
        super.doBusiness(savedInstanceState);

        if (savedInstanceState == null) {
            // 登陆私有房间
            BizLivePresenter.getInstance().loginPrivateRoom(mRoomKey);
            showMainMsg(getString(R.string.start_to_login_private_room));
            printLog(getString(R.string.myself, getString(R.string.start_to_login_private_room_log, mRoomKey + "")));
        }
    }

    @Override
    protected void handleRespondMsg(boolean isRespondToMyRequest, long roomKey, boolean isAgreed, String fromUserName) {

    }
}
