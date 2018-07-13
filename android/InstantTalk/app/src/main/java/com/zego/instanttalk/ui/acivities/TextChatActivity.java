package com.zego.instanttalk.ui.acivities;

import android.app.Activity;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.support.v7.app.AlertDialog;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.text.TextUtils;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.zego.biz.BizUser;
import com.zego.instanttalk.R;
import com.zego.instanttalk.adapter.NewChatAdapter;
import com.zego.instanttalk.constants.IntentExtra;
import com.zego.instanttalk.entities.ChatMsg;
import com.zego.instanttalk.interfaces.OnPublicRoomListener;
import com.zego.instanttalk.interfaces.OnUpdateMsgListListener;
import com.zego.instanttalk.presenters.BizLivePresenter;
import com.zego.instanttalk.presenters.TextMessagePresenter;
import com.zego.instanttalk.ui.base.AbsBaseActivity;
import com.zego.instanttalk.utils.BackgroundUtil;

import java.util.ArrayList;
import java.util.List;

import butterknife.Bind;
import butterknife.OnClick;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public class TextChatActivity extends AbsBaseActivity {

    @Bind(R.id.et_massage)
    public EditText etMsg;

    @Bind(R.id.tv_user_name)
    public TextView tvUserName;

    @Bind(R.id.rlv_msg)
    public RecyclerView rlvMsg;

    private ArrayList<BizUser> mListToUser;

    private String mSession;

    private LinearLayoutManager mLinearLayoutManager;

    private NewChatAdapter mNewChatAdapter;

    protected AlertDialog mDialogHandleRequestPublish = null;

    public static void actionStart(Activity activity, ArrayList<BizUser> listToUser, String session) {
        Intent intent = new Intent(activity, TextChatActivity.class);
        intent.putParcelableArrayListExtra(IntentExtra.TO_USERS, listToUser);
        intent.putExtra(IntentExtra.SESSION, session);
        activity.startActivity(intent);
    }

    @Override
    protected int getContentViewLayout() {
        return R.layout.activity_chat;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        BizLivePresenter.getInstance().setOnPublicRoomListener(new OnPublicRoomListener() {
            @Override
            public void onLoginSuccessfully(long roomKey, long serverKey) {

            }

            @Override
            public void onLoginFailed(int errCode, long roomKey, long serverKey) {

            }

            @Override
            public void onLeaveRoom(int errCode) {
                BizLivePresenter.getInstance().loginPublicRoom();
            }

            @Override
            public void onCancelChat() {
                // 聊天发起人取消了此次聊天
                if(mDialogHandleRequestPublish != null && mDialogHandleRequestPublish.isShowing()){
                    mDialogHandleRequestPublish.dismiss();

                    Toast.makeText(TextChatActivity.this, getString(R.string.your_friend_has_canceled_the_chat), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onDisconnected(int errCode, long roomKey, long serverKey) {

            }

            @Override
            public void onShowRequestMsg(final List<BizUser> listToUser, final String magic, final long roomKey, String fromUserName) {

                if(!BackgroundUtil.getRunningTask(TextChatActivity.this)){
                    NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

                    NotificationCompat.Builder builder = new NotificationCompat.Builder(TextChatActivity.this);
                    builder.setContentTitle(getString(R.string.notification)).setContentText(getString(R.string.someone_requested_to_chat_with_you, fromUserName)).setSmallIcon(R.mipmap.ic_launcher).setAutoCancel(true);

                    builder.setContentIntent(PendingIntent.getActivity(TextChatActivity.this, 0, new Intent(TextChatActivity.this, TextChatActivity.class), 0));

                    notificationManager.notify(102, builder.build());
                }

                mDialogHandleRequestPublish = new AlertDialog.Builder(TextChatActivity.this).setTitle(getString(R.string.hint)).
                        setMessage(getString(R.string.someone_is_requesting_to_chat_with_you, fromUserName)).setPositiveButton(getString(R.string.Allow),
                        new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                BizLivePresenter.getInstance().respondVideoChat(listToUser, magic, true, roomKey);
                                ArrayList<BizUser> arrayList = new ArrayList<>();
                                for(BizUser user : listToUser){
                                    arrayList.add(user);
                                }
                                GuestActivity.actionStart(TextChatActivity.this, arrayList, roomKey);
                                dialog.dismiss();
                            }
                        }).setNegativeButton(getString(R.string.Deny), new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        BizLivePresenter.getInstance().respondVideoChat(listToUser, magic, false, roomKey);
                        dialog.dismiss();
                    }
                }).create();

                mDialogHandleRequestPublish.show();
            }
        }, mHandler);
    }

    @Override
    protected void initExtraData(Bundle savedInstanceState) {
        Intent intent = getIntent();
        mListToUser = intent.getParcelableArrayListExtra(IntentExtra.TO_USERS);
        mSession = intent.getStringExtra(IntentExtra.SESSION);

        if (mListToUser == null || mListToUser.size() == 0) {
            finish();
        }
    }

    @Override
    protected void initVariables(Bundle savedInstanceState) {
        if (TextUtils.isEmpty(mSession)) {
            mSession = TextMessagePresenter.getInstance().createSession(mListToUser);
        }
        TextMessagePresenter.getInstance().openSession(mSession);

        mNewChatAdapter = new NewChatAdapter(this);
        mLinearLayoutManager = new LinearLayoutManager(this);

    }

    @Override
    protected void initViews(Bundle savedInstanceState) {
        setChatTitle();

        rlvMsg.setLayoutManager(mLinearLayoutManager);
        rlvMsg.setAdapter(mNewChatAdapter);

        TextMessagePresenter.getInstance().setUpdateMsgListListener(mSession, new OnUpdateMsgListListener() {
            @Override
            public void onShowAllMsg(String session, List<ChatMsg> listMsg) {
                if (mSession.equals(session) && listMsg != null) {
                    mNewChatAdapter.setMsgList(listMsg);
                    rlvMsg.smoothScrollToPosition(listMsg.size() - 1);
                }
            }
        }, mHandler);

    }

    @Override
    protected void loadData(Bundle savedInstanceState) {

    }

    private void setChatTitle() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0, size = mListToUser.size(); i < size; i++) {
            sb.append(mListToUser.get(i).userName);
            if (i != size - 1) {
                sb.append("+");
            }
        }
        tvUserName.setText(sb.toString());
    }


    @OnClick(R.id.btn_send)
    public void sendMsg() {

        String msg = etMsg.getText().toString();
        if (TextUtils.isEmpty(msg)) {
            Toast.makeText(TextChatActivity.this, R.string.you_can_not_send_an_empty_message, Toast.LENGTH_SHORT).show();
            return;
        }
        etMsg.setText("");

//        List<BizUser> sessionMemberList = TextMessagePresenter.getInstance().getSessionMemberList(mSession);
//        if(sessionMemberList != null && sessionMemberList.size() > 0){
//            mListToUser.clear();
//            for(BizUser bizUser : sessionMemberList){
//                mListToUser.add(bizUser);
//            }
//        }

        setChatTitle();

        // 用户可能更新了ID或者
        TextMessagePresenter.getInstance().sendMsg(mSession, mListToUser, msg);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // 关闭会话
        TextMessagePresenter.getInstance().closeSession(mSession);
        // 清空回调
        TextMessagePresenter.getInstance().setUpdateMsgListListener(mSession, null, null);
    }

    @OnClick(R.id.tv_video_chat)
    public void startVideoChat() {
        if (mListToUser.size() > 2) {
            // 暂时只支持3人进行视频聊天
            ArrayList<BizUser> listUser = new ArrayList<>();
            listUser.add(mListToUser.get(0));
            listUser.add(mListToUser.get(1));
            HostActivity.actionStart(this, listUser);
        } else {
            HostActivity.actionStart(this, mListToUser);
        }
        finish();
    }

    @OnClick(R.id.tv_back)
    public void back() {
        finish();
    }
}
