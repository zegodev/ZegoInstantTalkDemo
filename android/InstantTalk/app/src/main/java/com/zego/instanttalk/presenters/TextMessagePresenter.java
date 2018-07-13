package com.zego.instanttalk.presenters;

import android.os.Handler;
import android.text.TextUtils;

import com.zego.biz.BizUser;
import com.zego.instanttalk.entities.ChatMsg;
import com.zego.instanttalk.entities.SessionInfo;
import com.zego.instanttalk.interfaces.OnUpdateMsgListListener;
import com.zego.instanttalk.interfaces.OnUpdateSessionInfoListener;
import com.zego.instanttalk.utils.BizLiveUitl;
import com.zego.instanttalk.utils.PreferenceUtil;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public class TextMessagePresenter {

    public static final String KEY_LIST_SESSION_INFO = "KEY_LIST_SESSION_INFO";
    public static final String KEY_MAP_ALL_MSG = "KEY_MAP_ALL_MSG";

    private static TextMessagePresenter sInstance;

    private LinkedList<SessionInfo> mListSessionInfo;
    private LinkedHashMap<String, List<ChatMsg>> mMapAllMsg;
    private Handler mHandlerSession;
    private Handler mHandlerMsgList;
    private OnUpdateSessionInfoListener mOnUpdateSessionInfoListener;
    private OnUpdateMsgListListener mOnUpdateMsgListListener;
    private int mUnreadMessageTotalCount = 0;

    /**
     * 标识用户当前正在聊天页面进行的会话.
     */
    private String mCurrentSession;

    private ExecutorService mExecutorService;

    private TextMessagePresenter() {
        mExecutorService = Executors.newFixedThreadPool(4);

        new Thread(new Runnable() {
            @Override
            public void run() {
                mListSessionInfo = (LinkedList<SessionInfo>) PreferenceUtil.getInstance().getObjectFromString(KEY_LIST_SESSION_INFO);
                if (mListSessionInfo == null) {
                    mListSessionInfo = new LinkedList<>();
                }

                mMapAllMsg = (LinkedHashMap<String, List<ChatMsg>>) PreferenceUtil.getInstance().getObjectFromString(KEY_MAP_ALL_MSG);
                if (mMapAllMsg == null) {
                    mMapAllMsg = new LinkedHashMap<>();
                }
            }
        }).run();
    }

    public static TextMessagePresenter getInstance() {
        if (sInstance == null) {
            synchronized (TextMessagePresenter.class) {
                if (sInstance == null) {
                    sInstance = new TextMessagePresenter();
                }
            }
        }

        return sInstance;
    }

    /**
     * 用户进入聊天页面, 创建会话session.
     *
     * @param listToUser
     * @return
     */
    public String createSession(List<BizUser> listToUser) {
        String session = null;

        if (listToUser != null && listToUser.size() == 1) {
            for (SessionInfo sessionInfo : mListSessionInfo) {
                List<BizUser> sessionMembers = sessionInfo.getListUser();
                if (sessionMembers.size() == 1) {
                    if (listToUser.get(0).userID.equals(sessionMembers.get(0).userID)) {
                        session = sessionInfo.getSession();
                        break;
                    }
                }
            }
        }

        if (TextUtils.isEmpty(session)) {
            session = PreferenceUtil.getInstance().getUserID() + "+" + System.currentTimeMillis();
        }

        return session;
    }

    /**
     * 开启会话, 需要校验session是否存在.
     *
     * @param session
     */
    public void openSession(String session) {
        if (!TextUtils.isEmpty(session)) {
            mCurrentSession = session;
        }
    }

    /**
     * 用户离开聊天页面, 关闭会话session.
     *
     * @param session
     */
    public void closeSession(String session) {
        if (!TextUtils.isEmpty(session) && session.equals(mCurrentSession)) {
            mCurrentSession = null;
        }
    }

    /**
     * 删除session.
     *
     * @param session
     */
    public void deleteSession(final String session) {
        mExecutorService.execute(new Runnable() {
            @Override
            public void run() {
                if (TextUtils.isEmpty(session)) {
                    return;
                }

                // 删除sessionInfo以及相应的消息列表
                for (SessionInfo sessionInfo : mListSessionInfo) {
                    if (sessionInfo.getSession().equals(session)) {
                        mListSessionInfo.remove(sessionInfo);
                        mMapAllMsg.remove(session);
                        break;
                    }
                }

                // 更新界面
                if (mOnUpdateSessionInfoListener != null && mHandlerSession != null) {
                    mHandlerSession.post(new Runnable() {
                        @Override
                        public void run() {
                            mOnUpdateSessionInfoListener.onUpdateSessionInfo(mListSessionInfo, mUnreadMessageTotalCount);
                        }
                    });
                }

                // 将信息持久化
                PreferenceUtil.getInstance().setObjectToString(KEY_LIST_SESSION_INFO, mListSessionInfo);
                PreferenceUtil.getInstance().setObjectToString(KEY_MAP_ALL_MSG, mMapAllMsg);
            }
        });
    }

    public void setOnUpdateSessionInfoListener(final OnUpdateSessionInfoListener listener, final Handler handler) {
        mOnUpdateSessionInfoListener = listener;
        mHandlerSession = handler;

        if (listener != null && handler != null) {
            handler.post(new Runnable() {
                @Override
                public void run() {

                    mOnUpdateSessionInfoListener.onUpdateSessionInfo(mListSessionInfo, mUnreadMessageTotalCount);
                }
            });
        }
    }

    public void setUpdateMsgListListener(final String session, final OnUpdateMsgListListener listener, final Handler handler) {
        mOnUpdateMsgListListener = listener;
        mHandlerMsgList = handler;

        if (listener != null && handler != null) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    mOnUpdateMsgListListener.onShowAllMsg(session, mMapAllMsg.get(session));
                }
            });
        }
    }

    public OnUpdateMsgListListener getOnUpdateMsgListListener() {
        return mOnUpdateMsgListListener;
    }

    public List<BizUser> getSessionMemberList(String session) {
        List<BizUser> sessionMemberList = null;

        for (SessionInfo sessionInfo : mListSessionInfo) {
            if (sessionInfo.getSession().equals(session)) {
                sessionMemberList = sessionInfo.getListUser();
                break;
            }
        }

        return sessionMemberList;
    }

    public void readAllMessage() {
        mUnreadMessageTotalCount = 0;
    }


    public void receiveMsg(HashMap<String, Object> mapData, final List<BizUser> listToUser, final BizUser fromUser) {

        final String session = (String) mapData.get(BizLiveUitl.KEY_MESSAGE_SESSION);
        if (TextUtils.isEmpty(session)) {
            return;
        }

        SessionInfo oldSessionInfo = null;
        for (SessionInfo sessionInfo : mListSessionInfo) {
            if (sessionInfo.getSession().equals(session)) {
                oldSessionInfo = sessionInfo;
                mListSessionInfo.remove(sessionInfo);
                break;
            }
        }
        if (oldSessionInfo == null) {
            oldSessionInfo = new SessionInfo();
            oldSessionInfo.setSession(session);
            oldSessionInfo.setUnreadMsgCount(0);
        }

        oldSessionInfo.setNewestContent((String) mapData.get(BizLiveUitl.KEY_TALK_CONTENT));
        oldSessionInfo.setFromUserID(fromUser.userID);
        oldSessionInfo.setFromUserName(fromUser.userName);
        oldSessionInfo.setCreatedTime(System.currentTimeMillis() / 1000);
        oldSessionInfo.setListUser(listToUser);
        mListSessionInfo.addFirst(oldSessionInfo);

        if (!session.equals(mCurrentSession)) {
            mUnreadMessageTotalCount += 1;
            oldSessionInfo.setUnreadMsgCount(oldSessionInfo.getUnreadMsgCount() + 1);
        }

        // 通知界面更新消息
        if (mOnUpdateSessionInfoListener != null && mHandlerSession != null) {
            mHandlerSession.post(new Runnable() {
                @Override
                public void run() {
                    mOnUpdateSessionInfoListener.onUpdateSessionInfo(mListSessionInfo, mUnreadMessageTotalCount);
                    mOnUpdateSessionInfoListener.onNotifyMsgComing(fromUser.userName);
                }
            });
        }


        ChatMsg newMsg = new ChatMsg();
        newMsg.setFromUserID(fromUser.userID);
        newMsg.setFromUserName(fromUser.userName);
        newMsg.setContent((String) mapData.get(BizLiveUitl.KEY_TALK_CONTENT));
        newMsg.setType(ChatMsg.VALUE_LEFT_TEXT);
        newMsg.setSession(session);

        // 更新消息列表
        List<ChatMsg> listMsg = mMapAllMsg.get(session);
        if (listMsg == null) {
            listMsg = new ArrayList<>();
            mMapAllMsg.put(session, listMsg);
        }
        listMsg.add(newMsg);

        // 通知界面更新消息
        final List<ChatMsg> listMsgTemp = listMsg;
        if (mOnUpdateMsgListListener != null && mHandlerMsgList != null) {
            mHandlerMsgList.post(new Runnable() {
                @Override
                public void run() {
                    mOnUpdateMsgListListener.onShowAllMsg(session, listMsgTemp);
                }
            });
        }

        // 将信息持久化
        PreferenceUtil.getInstance().setObjectToString(KEY_LIST_SESSION_INFO, mListSessionInfo);
        PreferenceUtil.getInstance().setObjectToString(KEY_MAP_ALL_MSG, mMapAllMsg);
    }


    public void sendMsg(final String session, final List<BizUser> listToUser, final String content) {

        mExecutorService.execute(new Runnable() {
            @Override
            public void run() {

                if (TextUtils.isEmpty(session) || listToUser == null || listToUser.size() == 0 || TextUtils.isEmpty(content)) {
                    return;
                }

                BizLivePresenter.getInstance().sendTextMsg(session, listToUser, content);

                SessionInfo oldSessionInfo = null;
                for (SessionInfo sessionInfo : mListSessionInfo) {
                    if (sessionInfo.getSession().equals(session)) {
                        oldSessionInfo = sessionInfo;
                        mListSessionInfo.remove(sessionInfo);
                        break;
                    }
                }
                if (oldSessionInfo == null) {
                    oldSessionInfo = new SessionInfo();
                    oldSessionInfo.setSession(session);
                    oldSessionInfo.setUnreadMsgCount(0);

                }
                oldSessionInfo.setFromUserID(PreferenceUtil.getInstance().getUserID());
                oldSessionInfo.setFromUserName(PreferenceUtil.getInstance().getUserName());
                oldSessionInfo.setNewestContent(content);
                oldSessionInfo.setCreatedTime(System.currentTimeMillis() / 1000);
                oldSessionInfo.setListUser(listToUser);
                mListSessionInfo.addFirst(oldSessionInfo);

                // 通知界面更新消息
                if (mOnUpdateSessionInfoListener != null && mHandlerSession != null) {
                    mHandlerSession.post(new Runnable() {
                        @Override
                        public void run() {
                            mOnUpdateSessionInfoListener.onUpdateSessionInfo(mListSessionInfo, 0);
                        }
                    });
                }


                ChatMsg newMsg = new ChatMsg();
                newMsg.setFromUserID(PreferenceUtil.getInstance().getUserID());
                newMsg.setFromUserName(PreferenceUtil.getInstance().getUserName());
                newMsg.setContent(content);
                newMsg.setType(ChatMsg.VALUE_RIGHT_TEXT);
                newMsg.setSession(session);

                // 更新消息列表
                List<ChatMsg> listMsg = mMapAllMsg.get(session);
                if (listMsg == null) {
                    listMsg = new ArrayList<>();
                    mMapAllMsg.put(session, listMsg);
                }
                listMsg.add(newMsg);

                // 通知界面更新消息
                final List<ChatMsg> listMsgTemp = listMsg;
                if (mOnUpdateMsgListListener != null && mHandlerMsgList != null) {
                    mHandlerMsgList.post(new Runnable() {
                        @Override
                        public void run() {
                            mOnUpdateMsgListListener.onShowAllMsg(session, listMsgTemp);
                        }
                    });
                }

                // 将信息持久化
                PreferenceUtil.getInstance().setObjectToString(KEY_LIST_SESSION_INFO, mListSessionInfo);
                PreferenceUtil.getInstance().setObjectToString(KEY_MAP_ALL_MSG, mMapAllMsg);
            }
        });
    }

}
