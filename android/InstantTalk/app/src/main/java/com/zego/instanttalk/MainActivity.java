package com.zego.instanttalk;

import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.app.NotificationCompat;
import android.support.v4.view.ViewPager;
import android.support.v7.app.AlertDialog;
import android.support.v7.widget.Toolbar;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Toast;

import com.tencent.tauth.Tencent;
import com.zego.biz.BizUser;
import com.zego.instanttalk.constants.Constants;
import com.zego.instanttalk.interfaces.OnPublicRoomListener;
import com.zego.instanttalk.presenters.BizLivePresenter;
import com.zego.instanttalk.ui.acivities.AboutZegoActivity;
import com.zego.instanttalk.ui.acivities.GuestActivity;
import com.zego.instanttalk.ui.acivities.SelectUsersActivity;
import com.zego.instanttalk.ui.base.AbsBaseActivity;
import com.zego.instanttalk.ui.base.AbsBaseFragment;
import com.zego.instanttalk.ui.fragments.SelectChatFragmentDialog;
import com.zego.instanttalk.ui.fragments.SessionListFragment;
import com.zego.instanttalk.ui.fragments.SettingFragment;
import com.zego.instanttalk.ui.fragments.UserListFragment;
import com.zego.instanttalk.ui.widgets.NavigationBar;
import com.zego.instanttalk.utils.BackgroundUtil;

import java.util.ArrayList;
import java.util.List;

import butterknife.Bind;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */
public class MainActivity extends AbsBaseActivity implements NavigationBar.NavigationBarListener {

    private List<AbsBaseFragment> mFragments;

    private FragmentPagerAdapter mPagerAdapter;

    protected AlertDialog mDialogHandleRequestPublish = null;

    @Bind(R.id.toolbar)
    public Toolbar toolBar;

    @Bind(R.id.nb)
    public NavigationBar navigationBar;

    @Bind(R.id.vp)
    public ViewPager viewPager;


    @Override
    protected int getContentViewLayout() {
        return R.layout.acvitity_main;
    }

    @Override
    protected void initExtraData(Bundle savedInstanceState) {

    }

    @Override
    protected void initVariables(Bundle savedInstanceState) {

        mFragments = new ArrayList<>();
        mFragments.add(UserListFragment.newInstance());
        mFragments.add(SessionListFragment.newInstance());
        mFragments.add(SettingFragment.newInstance());

        mPagerAdapter = new FragmentPagerAdapter(getSupportFragmentManager()) {
            @Override
            public Fragment getItem(int position) {
                return mFragments.get(position);
            }

            @Override
            public int getCount() {
                return mFragments.size();
            }
        };
    }

    @Override
    protected void initViews(Bundle savedInstanceState) {
        navigationBar.setNavigationBarListener(this);

        viewPager.setAdapter(mPagerAdapter);
        navigationBar.selectTab(0);
        viewPager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

            }

            @Override
            public void onPageSelected(int position) {
                navigationBar.selectTab(position);
            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });

        setSupportActionBar(toolBar);

    }

    @Override
    protected void loadData(Bundle savedInstanceState) {
        // 登陆公共房间
        BizLivePresenter.getInstance().loginPublicRoom();
    }


    @Override
    protected void onResume() {
        super.onResume();

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

                    Toast.makeText(MainActivity.this, getString(R.string.your_friend_has_canceled_the_chat), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onDisconnected(int errCode, long roomKey, long serverKey) {

            }

            @Override
            public void onShowRequestMsg(final List<BizUser> listToUser, final String magic, final long roomKey, String fromUserName) {

                if(!BackgroundUtil.getRunningTask(MainActivity.this)){
                    NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

                    NotificationCompat.Builder builder = new NotificationCompat.Builder(MainActivity.this);
                    builder.setContentTitle(getString(R.string.notification)).setContentText(getString(R.string.someone_requested_to_chat_with_you, fromUserName)).setSmallIcon(R.mipmap.ic_launcher).setAutoCancel(true);

                    builder.setContentIntent(PendingIntent.getActivity(MainActivity.this, 0, new Intent(MainActivity.this, MainActivity.class), 0));

                    notificationManager.notify(102, builder.build());
                }
                mDialogHandleRequestPublish = new AlertDialog.Builder(MainActivity.this).setTitle(getString(R.string.hint)).
                        setMessage(getString(R.string.someone_is_requesting_to_chat_with_you, fromUserName)).setPositiveButton(getString(R.string.Allow),
                        new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                BizLivePresenter.getInstance().respondVideoChat(listToUser, magic, true, roomKey);
                                ArrayList<BizUser> arrayList = new ArrayList<>();
                                for(BizUser user : listToUser){
                                    arrayList.add(user);
                                }
                                GuestActivity.actionStart(MainActivity.this, arrayList, roomKey);
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
    public void onTabSelect(int tabIndex) {
        viewPager.setCurrentItem(tabIndex, true);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            exit();
            return false;
        }
        return super.onKeyDown(keyCode, event);
    }

    /**
     * 用户连续点击两次返回键可以退出应用的时间间隔.
     */
    public static final long EXIT_INTERVAL = 1000;

    private long mBackPressedTime;

    /**
     * 退出.
     */
    private void exit() {
        /* 连按两次退出 */
        long currentTime = System.currentTimeMillis();
        if (currentTime - mBackPressedTime > EXIT_INTERVAL) {
            Toast.makeText(this, "再按一次退出程序", Toast.LENGTH_SHORT).show();
            mBackPressedTime = currentTime;
        } else {
            // 释放Zego sdk
            ZegoApiManager.getInstance().releaseSDK();

            // 退出大厅
            BizLivePresenter.getInstance().leavePublicRoom();
            BizLivePresenter.getInstance().uninit();
            System.exit(0);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        if(id == R.id.action_contact_us){
            Tencent.createInstance("", MainActivity.this).startWPAConversation(MainActivity.this, "84328558", "");
            return true;
        }

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_about) {
            AboutZegoActivity.actionStart(MainActivity.this);
            return true;
        }
        if(id == R.id.action_multi_users){
            final SelectChatFragmentDialog selectChatFragmentDialog = new SelectChatFragmentDialog();
            selectChatFragmentDialog.setSelectChatListener(new SelectChatFragmentDialog.OnSelectChatListener() {
                @Override
                public void onSelectMultiUsersChat() {
                    SelectUsersActivity.actionStart(MainActivity.this, Constants.CHAT_TYPE_TEXT);
                }

                @Override
                public void onSelectMultiUsersVideoChat() {
                     SelectUsersActivity.actionStart(MainActivity.this, Constants.CHAT_TYPE_VIDEO);
                }
            });
            selectChatFragmentDialog.show(getFragmentManager(), "selectChatDialog");
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    public NavigationBar getNavigationBar(){
        return navigationBar;
    }
}
