package com.zego.instanttalk.ui.fragments;

import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.support.v4.app.NotificationCompat;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.View;

import com.zego.biz.BizUser;
import com.zego.instanttalk.MainActivity;
import com.zego.instanttalk.R;
import com.zego.instanttalk.adapter.ListSessionAdapter;
import com.zego.instanttalk.adapter.SpaceItemDecoration;
import com.zego.instanttalk.ui.base.AbsBaseFragment;
import com.zego.instanttalk.entities.SessionInfo;
import com.zego.instanttalk.interfaces.OnUpdateSessionInfoListener;
import com.zego.instanttalk.presenters.TextMessagePresenter;
import com.zego.instanttalk.ui.acivities.TextChatActivity;
import com.zego.instanttalk.utils.BackgroundUtil;

import java.util.ArrayList;
import java.util.LinkedList;

import butterknife.Bind;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */
public class SessionListFragment extends AbsBaseFragment {

    @Bind(R.id.rlv_session_list)
    public RecyclerView rlvSessionList;

    private ListSessionAdapter mListSessionAdapter;

    private LinearLayoutManager mLinearLayoutManager;

    private boolean mIsVisibleToUser = false;

    public static SessionListFragment newInstance() {
        return new SessionListFragment();
    }

    @Override
    protected int getContentViewLayout() {
        return R.layout.fragment_session_list;
    }

    @Override
    protected void initExtraData() {

    }

    @Override
    protected void initVariables() {

        mListSessionAdapter = new ListSessionAdapter(mParentActivity);
        mListSessionAdapter.setOnItemClickListener(new ListSessionAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(View view, SessionInfo sessionInfo) {

                ArrayList<BizUser> listToUser = new ArrayList<>();
                for (BizUser user : sessionInfo.getListUser()) {
                    listToUser.add(user);
                }

                TextChatActivity.actionStart(mParentActivity, listToUser, sessionInfo.getSession());
            }

            @Override
            public void onItemLongClick(final SessionInfo sessionInfo) {
                DeleteSessionFragmentDialog dialog = new DeleteSessionFragmentDialog();
                dialog.setOnDeleteSessionListener(new DeleteSessionFragmentDialog.OnDeleteSessionListener() {
                    @Override
                    public void onDeleteSession() {
                        TextMessagePresenter.getInstance().deleteSession(sessionInfo.getSession());
                    }
                });

                dialog.show(mParentActivity.getFragmentManager(), "deleteSession");
            }
        });
    }

    @Override
    protected void initViews() {
        mLinearLayoutManager = new LinearLayoutManager(mParentActivity);
        rlvSessionList.setLayoutManager(mLinearLayoutManager);
        rlvSessionList.addItemDecoration(new SpaceItemDecoration(mResources.getDimensionPixelSize(R.dimen.dimen_5)));
        rlvSessionList.setAdapter(mListSessionAdapter);

    }

    @Override
    protected void loadData() {
        TextMessagePresenter.getInstance().setOnUpdateSessionInfoListener(new OnUpdateSessionInfoListener() {
            @Override
            public void onUpdateSessionInfo(LinkedList<SessionInfo> listSessionInfo, int unreadMsgTotalCount) {
                mListSessionAdapter.setSessionList(listSessionInfo);

                if (mIsVisibleToUser) {
                    TextMessagePresenter.getInstance().readAllMessage();
                } else {
                    ((MainActivity) mParentActivity).getNavigationBar().showUnreadMessageCount(unreadMsgTotalCount);
                }
            }

            @Override
            public void onNotifyMsgComing(String fromUserName) {
                if(!BackgroundUtil.getRunningTask(mParentActivity) && TextMessagePresenter.getInstance().getOnUpdateMsgListListener() == null){

                    NotificationManager notificationManager = (NotificationManager) mParentActivity.getSystemService(mParentActivity.NOTIFICATION_SERVICE);

                    NotificationCompat.Builder builder = new NotificationCompat.Builder(mParentActivity);
                    builder.setContentTitle(getString(R.string.notification)).setContentText(getString(R.string.someone_sent_you_a_text_message, fromUserName)).setSmallIcon(R.mipmap.ic_launcher).setAutoCancel(true);

                    builder.setContentIntent(PendingIntent.getActivity(mParentActivity, 0, new Intent(mParentActivity, MainActivity.class), 0));

                    notificationManager.notify(102, builder.build());
                }
            }
        }, mHandler);
    }

    @Override
    public void setUserVisibleHint(boolean isVisibleToUser) {
        super.setUserVisibleHint(isVisibleToUser);
        mIsVisibleToUser = isVisibleToUser;

        if(isVisibleToUser){
            TextMessagePresenter.getInstance().readAllMessage();
            mListSessionAdapter.notifyDataSetChanged();
            ((MainActivity) mParentActivity).getNavigationBar().showUnreadMessageCount(0);
        }
    }
}
