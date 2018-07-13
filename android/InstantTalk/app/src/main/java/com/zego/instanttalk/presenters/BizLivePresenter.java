package com.zego.instanttalk.presenters;

import android.content.Context;
import android.os.Handler;
import android.text.TextUtils;

import com.google.gson.Gson;
import com.google.gson.internal.LinkedTreeMap;
import com.google.gson.reflect.TypeToken;
import com.zego.biz.BizLiveRoom;
import com.zego.biz.BizStream;
import com.zego.biz.BizUser;
import com.zego.biz.callback.BizLiveCallback;
import com.zego.instanttalk.ZegoApplication;
import com.zego.instanttalk.interfaces.OnPrivateRoomListener;
import com.zego.instanttalk.interfaces.OnPublicRoomListener;
import com.zego.instanttalk.utils.BizLiveUitl;
import com.zego.instanttalk.utils.PreferenceUtil;
import com.zego.zegoavkit2.ZegoAVKit;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static com.zego.instanttalk.utils.BizLiveUitl.KEY_VIDEO_CANCEL_COMMAND;
import static com.zego.instanttalk.utils.BizLiveUitl.KEY_VIDEO_RESPOND_COMMAND;
import static com.zego.instanttalk.utils.BizLiveUitl.formatVideoChatMsg;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public class BizLivePresenter {

    private static final int COMMON_ROOM_KEY = 1;

    private static BizLivePresenter sInstance;

    /**
     * 业务类实例.
     */
    private BizLiveRoom mBizLiveRoom;

    /**
     * 公共房间监听器.
     */
    private OnPublicRoomListener mOnPublicRoomListener;

    /**
     * 私有房间监听器.
     */
    private OnPrivateRoomListener mOnPrivateRoomListener;

    private Handler mHandlerPublicRoom;

    private Handler mHandlerPrivateRoom;

    private ExecutorService mExecutorService;

    private String mMyMagic = "";

    private boolean mIsVideoChatting = false;

    private BizLivePresenter() {
        mBizLiveRoom = new BizLiveRoom();
        mExecutorService = Executors.newFixedThreadPool(4);
        init();
        initCallback();
    }

    public static BizLivePresenter getInstance() {
        if (sInstance == null) {
            synchronized (BizLivePresenter.class) {
                if (sInstance == null) {
                    sInstance = new BizLivePresenter();
                }
            }
        }
        return sInstance;
    }

    private void init() {
        mExecutorService.execute(new Runnable() {
            @Override
            public void run() {
                // 初始化用户信息
                String userID = PreferenceUtil.getInstance().getUserID();
                String userName = PreferenceUtil.getInstance().getUserName();

                if (TextUtils.isEmpty(userID) || TextUtils.isEmpty(userName)) {
                    long ms = System.currentTimeMillis();
                    userID = ms + "";
                    userName = "Android-" + ms;

                    // 保存用户信息
                    PreferenceUtil.getInstance().setUserID(userID);
                    PreferenceUtil.getInstance().setUserName(userName);
                }

                // 设置日志level
                mBizLiveRoom.setLogLevel(ZegoApplication.sApplicationContext, ZegoAVKit.LOG_LEVEL_DEBUG, null);

                byte[] signKey = {
                        (byte)0x18,  (byte)0x9d,  (byte)0x83,  (byte)0x5a,  (byte)0x62,  (byte)0xe8,  (byte)0xec,  (byte)0xbf,
                        (byte)0xc6,  (byte)0x58,  (byte)0x53,  (byte)0xeb,  (byte)0xaf,  (byte)0x26,  (byte)0x5a,  (byte)0xab,
                        (byte)0x34,  (byte)0x48,  (byte)0x58,  (byte)0x6f,  (byte)0x7a,  (byte)0x9d,  (byte)0xd0,  (byte)0x10,
                        (byte)0xee,  (byte)0xb3,  (byte)0x81,  (byte)0x78,  (byte)0x6d,  (byte)0x86,  (byte)0x18,  (byte)0x5d
                };
                long appID = 766949305L;

                mBizLiveRoom.init(appID, signKey, signKey.length, ZegoApplication.sApplicationContext);
            }
        });
    }

    private void initCallback() {
        mBizLiveRoom.setBizLiveCallback(new BizLiveCallback() {
            @Override
            public void onLoginRoom(int errCode, long roomKey, long serverKey, boolean isPublicRoom) {
                if (errCode == 0) {
                    if (isPublicRoom) {
                        if (mOnPublicRoomListener != null) {
                            mOnPublicRoomListener.onLoginSuccessfully(roomKey, serverKey);
                        }
                    } else {
                        if (mOnPrivateRoomListener != null) {
                            mOnPrivateRoomListener.onLoginSuccessfully(roomKey, serverKey);
                        }
                    }
                } else {
                    if (isPublicRoom) {
                        if (mOnPublicRoomListener != null) {
                            mOnPublicRoomListener.onLoginFailed(errCode, roomKey, serverKey);
                        }
                    } else {
                        if (mOnPrivateRoomListener != null) {
                            mOnPrivateRoomListener.onLoginFailed(errCode, roomKey, serverKey);
                        }
                    }
                }
            }

            @Override
            public void onLeaveRoom(int errCode, boolean isPublicRoom) {
                if (isPublicRoom) {
                    if (mOnPublicRoomListener != null) {
                        mOnPublicRoomListener.onLeaveRoom(errCode);
                    }
                } else {
                    if (mOnPrivateRoomListener != null) {
                        mOnPrivateRoomListener.onLeaveRoom(errCode);
                    }
                }
            }

            @Override
            public void onDisconnected(int errCode, long roomKey, long serverKey, boolean isPublicRoom) {
                if (isPublicRoom) {
                    if (mOnPublicRoomListener != null) {
                        mOnPublicRoomListener.onDisconnected(errCode, roomKey, serverKey);
                    }
                } else {
                    if (mOnPrivateRoomListener != null) {
                        mOnPrivateRoomListener.onDisconnected(errCode, roomKey, serverKey);
                    }
                }

            }

            @Override
            public void onKickOut(int i, String s, boolean isPublicRoom) {
                if (isPublicRoom) {
                    if (mOnPublicRoomListener != null) {
                    }
                } else {
                    if (mOnPrivateRoomListener != null) {
                    }
                }
            }

            @Override
            public void onStreamCreate(String streamID, String url, boolean isPublicRoom) {
                if (isPublicRoom) {
                    if (mOnPublicRoomListener != null) {
                    }
                } else {
                    if (mOnPrivateRoomListener != null) {
                        mOnPrivateRoomListener.onStreamCreate(streamID, url);
                    }
                }
            }

            @Override
            public void onStreamAdd(BizStream[] bizStreams, boolean isPublicRoom) {
                if (isPublicRoom) {
                    if (mOnPublicRoomListener != null) {
                    }
                } else {
                    if (mOnPrivateRoomListener != null) {
                        mOnPrivateRoomListener.onStreamAdd(bizStreams);
                    }
                }
            }

            @Override
            public void onStreamDelete(BizStream[] bizStreams, boolean isPublicRoom) {
                if (isPublicRoom) {
                    if (mOnPublicRoomListener != null) {
                    }
                } else {
                    if (mOnPrivateRoomListener != null) {
                        mOnPrivateRoomListener.onStreamDelete(bizStreams);
                    }
                }
            }

            @Override
            public void onReceiveMsg(int msgType, String data, boolean isPublicRoom) {
                if(isPublicRoom){
                    handleMsg(msgType, data);
                }
            }

            @Override
            public void onRoomUserUpdate(final BizUser[] bizUsers, final int flag, boolean isPublicRoom) {
                if (isPublicRoom) {
                    mExecutorService.execute(new Runnable() {
                        @Override
                        public void run() {
                            UserListPresenter.getInstance().updateUserList(bizUsers, flag);
                        }
                    });
                }
            }

            @Override
            public void onRoomUserCountUpdate(int i, boolean isPublicRoom) {

            }
        });
    }

    /**
     * 处理消息.
     */
    private void handleMsg(final int msgType, final String data) {
        mExecutorService.execute(new Runnable() {
            @Override
            public void run() {
                // 一对一聊天的消息类型都为"1"
                if (msgType != 1 || TextUtils.isEmpty(data)) {
                    return;
                }

                // 从json字符串中解析出数据
                final HashMap<String, Object> mapData = (new Gson()).fromJson(data, new TypeToken<HashMap<String, Object>>() {
                }.getType());

                if (mapData == null) {
                    return;
                }

                // 获取本条消息的"接收用户"
                List<BizUser> listToUser = getToUserList((List<Object>) mapData.get(BizLiveUitl.KEY_TALK_TO_USER));

                // 判断是否是发给自己的消息
                if (!isMyMsg(listToUser)) {
                    return;
                }

                // 获取本条消息的"来源用户"
                LinkedTreeMap<String, String> mapFromUser = (LinkedTreeMap<String, String>) mapData.get(BizLiveUitl.KEY_TALK_FROM_USER);
                if (mapFromUser == null) {
                    return;
                }
                BizUser fromUser = new BizUser();
                fromUser.userID = mapFromUser.get(BizLiveUitl.KEY_TALK_USER_ID);
                fromUser.userName = mapFromUser.get(BizLiveUitl.KEY_TALK_USER_NAME);

                //移除自己
                String myUserID = PreferenceUtil.getInstance().getUserID();
                for (BizUser toUser : listToUser) {
                    if (myUserID.equals(toUser.userID)) {
                        listToUser.remove(toUser);
                        break;
                    }
                }
                // "来源用户"加入"目的用户列表", 用于稍后发送消息
                listToUser.add(fromUser);

                // 分发消息
                String command = (String) mapData.get(BizLiveUitl.KEY_TALK_COMMAND);

                if (mapFromUser != null) {
                    if (BizLiveUitl.KEY_VIDEO_REQUEST_COMMAND.equals(command)) {

                        receiveVideoRequestMsg(mapData, listToUser, fromUser);

                    } else if (KEY_VIDEO_RESPOND_COMMAND.equals(command)) {

                        receiveVideoRespondMsg(mapData, fromUser);

                    } else if (BizLiveUitl.KEY_MESSAGE_COMMAND.equals(command)) {

                        TextMessagePresenter.getInstance().receiveMsg(mapData, listToUser, fromUser);

                    } else if (KEY_VIDEO_CANCEL_COMMAND.equals(command)) {
                        if(mOnPublicRoomListener != null && mHandlerPublicRoom != null){
                            mHandlerPublicRoom.post(new Runnable() {
                                @Override
                                public void run() {
                                    mOnPublicRoomListener.onCancelChat();
                                }
                            });
                        }
                    }
                }
            }
        });
    }

    /**
     * 接收"请求视频聊天"的消息.
     */
    private void receiveVideoRequestMsg(HashMap<String, Object> mapData, final List<BizUser> listToUser, final BizUser fromUser) {

        final String magic = (String) mapData.get(BizLiveUitl.KEY_VIDEO_MAGIC);
        final long roomKey = (long) ((double) mapData.get(BizLiveUitl.KEY_VIDEO_ROOMID));

        // 用户正在视频中，拒绝其他聊天请求
        if (mIsVideoChatting) {
            respondVideoChat(listToUser, magic, false, roomKey);
            return;
        }

        if(mOnPublicRoomListener != null && mHandlerPublicRoom != null){
            mHandlerPublicRoom.post(new Runnable() {
                @Override
                public void run() {
                    mOnPublicRoomListener.onShowRequestMsg(listToUser, magic, roomKey, fromUser.userName);
                }
            });
        }
    }

    /**
     * 接收"响应视频聊天请求"的消息.
     */
    private void receiveVideoRespondMsg(HashMap<String, Object> mapData, final BizUser fromUser) {

        final String magic = (String) mapData.get(BizLiveUitl.KEY_VIDEO_MAGIC);
        final long roomKey = (long) ((double) mapData.get(BizLiveUitl.KEY_VIDEO_ROOMID));

        // 判断本条消息是否是响应"我"之前发出的请求
        final boolean isRespondToMyRequest = mMyMagic.equals(magic);

        String content = (String) mapData.get(BizLiveUitl.KEY_TALK_CONTENT);
        boolean isAgree = BizLiveUitl.KEY_VIDEO_AGREE.equals(content);

        final boolean isAgreeTemp = isAgree;
        if (mOnPrivateRoomListener != null && mHandlerPrivateRoom != null) {
            mHandlerPrivateRoom.post(new Runnable() {
                @Override
                public void run() {
                    mOnPrivateRoomListener.onShowRespondMsg(isRespondToMyRequest, roomKey, isAgreeTemp, fromUser.userName);
                }
            });
        }
    }

    /**
     * 获取目的用户列表.
     */
    private List<BizUser> getToUserList(List<Object> listObject) {
        List<BizUser> listToUser = new ArrayList<>();

        if (listObject != null) {
            for (Object object : listObject) {

                LinkedTreeMap<String, String> mapUser = (LinkedTreeMap<String, String>) object;
                if (mapUser != null) {
                    BizUser bizUser = new BizUser();
                    bizUser.userID = mapUser.get(BizLiveUitl.KEY_TALK_USER_ID);
                    bizUser.userName = mapUser.get(BizLiveUitl.KEY_TALK_USER_NAME);

                    listToUser.add(bizUser);
                }
            }
        }

        return listToUser;
    }

    /**
     * 判断本条消息是否发给自己.
     */
    private boolean isMyMsg(List<BizUser> listToUser) {
        if(listToUser == null){
            return false;
        }

        boolean isMyMsg = false;
        String myUserID = PreferenceUtil.getInstance().getUserID();

        for (BizUser bizUser : listToUser) {
            if (myUserID.equals(bizUser.userID)) {
                isMyMsg = true;
                break;
            }
        }

        return isMyMsg;
    }

    public void setOnPublicRoomListener(OnPublicRoomListener onPublicRoomListener, Handler handlerPublicRoom) {
        mOnPublicRoomListener = onPublicRoomListener;
        mHandlerPublicRoom = handlerPublicRoom;
    }

    public void setOnPrivateRoomListener(OnPrivateRoomListener onPrivateRoomListener, Handler handlerPrivateRoom) {
        mOnPrivateRoomListener = onPrivateRoomListener;
        mHandlerPrivateRoom = handlerPrivateRoom;
    }

    /**
     * 登陆公共房间.
     */
    public void loginPublicRoom() {
        mBizLiveRoom.getInCustomRoom(COMMON_ROOM_KEY, PreferenceUtil.getInstance().getUserID(),
                PreferenceUtil.getInstance().getUserName(), true);
    }

    /**
     * 登陆私有房间.
     */
    public void loginPrivateRoom(long roomKey) {
        mBizLiveRoom.getInCustomRoom(roomKey, PreferenceUtil.getInstance().getUserID(),
                PreferenceUtil.getInstance().getUserName(), false);
    }

    /**
     * 离开公共房间.
     */
    public void leavePublicRoom() {
        mBizLiveRoom.leaveRoom(true);
    }

    /**
     * 离开私有房间.
     */
    public void leavePrivateRoom() {
        mBizLiveRoom.leaveRoom(false);
    }

    /**
     * 设置视频聊天状态.
     */
    public void setVideoChatState(boolean isVideoChatting) {
        mIsVideoChatting = isVideoChatting;
    }


    /**
     * 请求视频聊天.
     */
    public void requestVideoChat(List<BizUser> listToUsers) {

        if (listToUsers == null || listToUsers.size() == 0) {
            return;
        }

        long below = System.currentTimeMillis() & 0xFFFF;
        long high = (Long.valueOf(PreferenceUtil.getInstance().getUserID()) << 16) & 0xFFFF0000L;
        long roomKey = (high | below);
        if (roomKey <= COMMON_ROOM_KEY) {
            roomKey = (long) Math.random();
        }

        mMyMagic = PreferenceUtil.getInstance().getUserID();

        String data = formatVideoChatMsg(BizLiveUitl.KEY_VIDEO_REQUEST_COMMAND, listToUsers, mMyMagic, true, roomKey);
        if(!TextUtils.isEmpty(data)){
            mBizLiveRoom.sendBroadcastTextMsg(data, true);
        }
    }

    /**
     * 响应视频聊天.
     */
    public void respondVideoChat(List<BizUser> listToUsers, String magic, boolean isAgreed, long roomKey) {

        if (listToUsers == null || listToUsers.size() == 0) {
            return;
        }

        String data = BizLiveUitl.formatVideoChatMsg(BizLiveUitl.KEY_VIDEO_RESPOND_COMMAND, listToUsers, magic, isAgreed, roomKey);

        if (!TextUtils.isEmpty(data)) {
            mBizLiveRoom.sendBroadcastTextMsg(data, true);
        }
    }

    /**
     *  取消视频聊天.
     */
    public void cancelVideoChat(List<BizUser> listToUsers, long roomKey) {

        if (listToUsers == null || listToUsers.size() == 0) {
            return;
        }

        String data = BizLiveUitl.formatVideoChatMsg(BizLiveUitl.KEY_VIDEO_CANCEL_COMMAND, listToUsers, mMyMagic, false, roomKey);

        if (!TextUtils.isEmpty(data)) {
            mBizLiveRoom.sendBroadcastTextMsg(data, true);
        }
    }

    /**
     * 发送文字聊天消息.
     */
    public void sendTextMsg(String session, List<BizUser> listToUser, String content){
        if (TextUtils.isEmpty(session) || TextUtils.isEmpty(content) || listToUser == null || listToUser.size() == 0) {
            return;
        }

        String data = BizLiveUitl.formatTextMsg(session, listToUser, content);

        if (!TextUtils.isEmpty(data)) {
            mBizLiveRoom.sendBroadcastTextMsg(data, true);
        }
    }

    /**
     * 获取私有房间的流列表.
     */
    public void getStreamListInPrivateRoom(){
        mBizLiveRoom.getStreamList(false);
    }

    /**
     * 在私有房间中创建流.
     */
    public void createStreamInPrivateRoom(String streamTitle, String streamID){
        mBizLiveRoom.createSreamInRoom(streamTitle, streamID, false);
    }

    /**
     * 通知业务服务器私有房间中的流的状态.
     */
    public void reportStreamStateInPrivateRoom(boolean isActive, String streamID, String userID){
        mBizLiveRoom.reportStreamState(isActive, streamID, userID, false);
    }

    public void init(long appID, byte[] appSign, int signLen, Context context){
        mBizLiveRoom.init(appID, appSign, signLen, context);
    }

    public void uninit(){
        mBizLiveRoom.uninit();
    }
}
