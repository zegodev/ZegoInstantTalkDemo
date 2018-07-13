package com.zego.instanttalk.ui.acivities;

import android.os.Bundle;
import android.text.TextUtils;

import com.zego.biz.BizStream;
import com.zego.biz.BizUser;
import com.zego.instanttalk.R;
import com.zego.instanttalk.constants.IntentExtra;
import com.zego.instanttalk.interfaces.OnPrivateRoomListener;
import com.zego.instanttalk.presenters.BizLivePresenter;
import com.zego.instanttalk.ui.widgets.ViewLive;
import com.zego.instanttalk.utils.BizLiveUitl;
import com.zego.instanttalk.utils.CommonUtil;
import com.zego.instanttalk.utils.PreferenceUtil;
import com.zego.zegoavkit2.ZegoAVKitCommon;
import com.zego.zegoavkit2.entity.ZegoUser;

import java.util.ArrayList;
import java.util.HashMap;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public abstract class BaseVideoChatActivity extends BaseLiveActivity {

    protected ArrayList<BizUser> mListToUser = new ArrayList<>();

    protected ArrayList<BizStream> mListStream = new ArrayList<>();

    protected HashMap<String, String> mMapStreamToUser = new HashMap<>();

    protected long mRoomKey;

    protected boolean mHaveLoginPrivateRoom = false;

    protected int mPlayCount = 0;

    protected abstract void handleRespondMsg(boolean isRespondToMyRequest, long roomKey, boolean isAgreed, String fromUserName);

    @Override
    protected void initExtraData(Bundle savedInstanceState) {
        super.initExtraData(savedInstanceState);
        if (savedInstanceState == null) {
            mListToUser = getIntent().getParcelableArrayListExtra(IntentExtra.TO_USERS);
            if (CommonUtil.isListEmpty(mListToUser)) {
                finish();
            }
        }
    }

    @Override
    protected void initViews(Bundle savedInstanceState) {
        super.initViews(savedInstanceState);

        ViewLive freeViewLive = getFreeViewLive();
        if (freeViewLive == null) {
            return;
        }
        // 提前预览
        mZegoAVKit.setLocalView(freeViewLive.getTextureView());
        mZegoAVKit.startPreview();
        mZegoAVKit.setLocalViewMode(ZegoAVKitCommon.ZegoVideoViewMode.ScaleAspectFill);

    }

    @Override
    protected void initVariables(Bundle savedInstanceState) {
        super.initVariables(savedInstanceState);

        BizLivePresenter.getInstance().setOnPrivateRoomListener(new OnPrivateRoomListener() {
            @Override
            public void onLoginSuccessfully(long roomKey, long serverKey) {
                mHaveLoginPrivateRoom = true;

                mChannel = BizLiveUitl.getChannel(roomKey, serverKey);

                showMainMsg(getString(R.string.login_private_room_success));
                printLog(getString(R.string.myself, getString(R.string.login_private_room_success_log, "0x" + Long.toHexString(roomKey), "0x" + Long.toHexString(serverKey))));

                // 登陆频道
                ZegoUser zegoUser = new ZegoUser(PreferenceUtil.getInstance().getUserID(), PreferenceUtil.getInstance().getUserName());
                mZegoAVKit.loginChannel(zegoUser, mChannel);
                printLog(getString(R.string.myself, getString(R.string.start_to_login_channel, mChannel)));

                // 获取流列表
                BizLivePresenter.getInstance().getStreamListInPrivateRoom();
            }

            @Override
            public void onLoginFailed(int errCode, long roomKey, long serverKey) {
                showMainMsg(getString(R.string.login_private_room_failed));
                printLog(getString(R.string.myself, getString(R.string.login_private_room_failed_log, "0x" + Long.toHexString(roomKey), "0x" + Long.toHexString(serverKey))));
            }

            @Override
            public void onLeaveRoom(int errCode) {

            }

            @Override
            public void onDisconnected(int errCode, long roomKey, long serverKey) {
                showMainMsg(getString(R.string.you_have_disconnected));
                printLog(getString(R.string.myself, getString(R.string.you_have_disconnected)));
            }

            @Override
            public void onStreamCreate(String streamID, String url) {
                if (!TextUtils.isEmpty(streamID)) {
                    mPublishStreamID = streamID;

                    printLog(getString(R.string.myself, getString(R.string.create_stream_success, streamID)));
                    startPublish();
                } else {
                    printLog(getString(R.string.myself, getString(R.string.create_stream_fail, streamID)));
                }
            }

            @Override
            public void onStreamAdd(BizStream[] bizStreams) {
                if (bizStreams != null && bizStreams.length > 0) {
                    for (BizStream bizStream : bizStreams) {
                        printLog(getString(R.string.someone_created_stream, bizStream.userName, bizStream.streamID));
                        // 存储流信息
                        mMapStreamToUser.put(bizStream.streamID, bizStream.userName);

                        if (mHaveLoginedChannel) {
                            startPlay(bizStream.streamID, getFreeZegoRemoteViewIndex());
                        } else {
                            // 未登录的情况下, 先存储流信息, 等待登陆成功后再播放
                            mListStream.add(bizStream);
                        }
                    }
                }
            }

            @Override
            public void onStreamDelete(BizStream[] bizStreams) {
                if (bizStreams != null && bizStreams.length > 0) {
                    for (BizStream bizStream : bizStreams) {
                        printLog(getString(R.string.someone_deleted_stream, bizStream.userName, bizStream.streamID));
                        stopPlay(bizStream.streamID);
                    }
                }
            }

            @Override
            public void onShowRespondMsg(boolean isRespondToMyRequest, long roomKey, boolean isAgreed, String fromUserName) {
                handleRespondMsg(isRespondToMyRequest, roomKey, isAgreed, fromUserName);
            }
        }, mHandler);
    }

    @Override
    protected void doBusiness(Bundle savedInstanceState) {
        super.doBusiness(savedInstanceState);
        // 设置视频聊天状态, 此时不接受其它聊天请求
        BizLivePresenter.getInstance().setVideoChatState(true);
    }

    @Override
    protected void doLiveBusinessAfterLoginChannel() {
        mPublishTitle = PreferenceUtil.getInstance().getUserName() + " is coming";
        BizLivePresenter.getInstance().createStreamInPrivateRoom(mPublishTitle, mPublishStreamID);
        printLog(getString(R.string.myself, getString(R.string.start_to_create_stream)));

        for (BizStream bizStream : mListStream) {
            startPlay(bizStream.streamID, getFreeZegoRemoteViewIndex());
        }
    }

    @Override
    protected void afterPublishingSuccess(String streamID) {
        BizLivePresenter.getInstance().reportStreamStateInPrivateRoom(true, streamID, PreferenceUtil.getInstance().getUserID());
    }

    @Override
    protected void afterPublishingStop(String streamID) {
        BizLivePresenter.getInstance().reportStreamStateInPrivateRoom(false, streamID, PreferenceUtil.getInstance().getUserID());
    }

    @Override
    protected void afterPlayingSuccess(String streamID) {
        mPlayCount++;

        showSubMsg(getString(R.string.someone_has_entered_the_room, mMapStreamToUser.get(streamID)));
        showMainMsg(getString(R.string.chatting));
    }

    @Override
    protected void afterPlayingStop(String streamID) {
        mPlayCount--;

        showSubMsg(getString(R.string.someone_has_left_the_room, mMapStreamToUser.get(streamID)));
        if (mPlayCount <= 0) {
            showMainMsg(getString(R.string.chat_finished));
            showSubMsg(getString(R.string.all_friends_have_left_the_room));
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        // 离开房间
        BizLivePresenter.getInstance().setVideoChatState(false);
        BizLivePresenter.getInstance().setOnPrivateRoomListener(null, null);

        if (mHaveLoginPrivateRoom) {
            BizLivePresenter.getInstance().leavePrivateRoom();
        }
    }
}
