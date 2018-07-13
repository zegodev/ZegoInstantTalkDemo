package com.zego.instanttalk.ui.acivities;


import android.app.Service;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.hardware.display.DisplayManager;
import android.os.Build;
import android.os.Bundle;
import android.support.design.widget.BottomSheetBehavior;
import android.support.v7.app.AlertDialog;
import android.telephony.PhoneStateListener;
import android.telephony.TelephonyManager;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.Surface;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.zego.instanttalk.R;
import com.zego.instanttalk.ZegoApiManager;
import com.zego.instanttalk.presenters.BizLivePresenter;
import com.zego.instanttalk.ui.base.AbsShowActivity;
import com.zego.instanttalk.ui.widgets.PublishSettingsPannel;
import com.zego.instanttalk.ui.widgets.ViewLive;
import com.zego.instanttalk.utils.PreferenceUtil;
import com.zego.instanttalk.utils.ZegoAVKitUtil;
import com.zego.zegoavkit2.AuxData;
import com.zego.zegoavkit2.ZegoAVKit;
import com.zego.zegoavkit2.ZegoAVKitCommon;
import com.zego.zegoavkit2.callback.ZegoLiveCallback;
import com.zego.zegoavkit2.entity.ZegoUser;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import butterknife.OnClick;

/**
 * des: 主页面
 */
public abstract class BaseLiveActivity extends AbsShowActivity {

    private static final String KEY_CHANNEL = "KEY_CHANNEL";

    private static final String KEY_PUBLISH_TITLE = "KEY_PUBLISH_TITLE";

    private static final String KEY_PUBLISH_STREAM_ID = "KEY_PUBLISH_STREAM_ID";

    private static final String KEY_ENABLE_CAMERA = "KEY_ENABLE_CAMERA";

    private static final String KEY_ENABLE_FRONT_CAM = "KEY_ENABLE_FRONT_CAM";

    private static final String KEY_ENABLE_TORCH = "KEY_ENABLE_TORCH";

    private static final String KEY_ENABLE_MIC = "KEY_ENABLE_MIC";

    private static final String KEY_HAVE_LOGINNED_CHANNEL = "KEY_HAVE_LOGINNED_CHANNEL";

    private static final String KEY_SELECTED_BEAUTY = "KEY_SELECTED_BEAUTY";

    private static final String KEY_SELECTED_FILTER = "KEY_SELECTED_FILTER";

    private static final String KEY_LIST_LIVEVIEW_TAG = "KEY_LIST_LIVEVIEW_TAG";

    public static final String KEY_LIST_LOG = "KEY_LIST_LOG";

    private static final String KEY_CAMERA_CAPTURE_ROTATION = "KEY_CAMERA_CAPTURE_ROTATION";

    private static final String EMPTY_STREAM_ID = "EMPTY_STREAM_ID";

    protected ZegoAVKit mZegoAVKit;

    private LinkedList<ViewLive> mListViewLive = new LinkedList<>();
    private List<String> mListLiveViewTag = new ArrayList<>();
    private List<String> mListLiveViewTagForCallComing = new ArrayList<>();
    private LinkedHashMap<ZegoAVKitCommon.ZegoRemoteViewIndex, String> mMapFreeViewIndex;
    private LinkedList<String> mListLog = new LinkedList<>();
    private Map<String, Boolean> mMapReplayStreamID = new HashMap<>();

    private BottomSheetBehavior mBehavior;

    private RelativeLayout mRlytControlHeader;

    private TextView mTvMainMsg;

    private TextView mTvSubMsg;

    protected String mPublishTitle;

    protected String mPublishStreamID;

    protected String mChannel;

    private boolean mEnableCamera = true;

    private boolean mEnableFrontCam = true;

    private boolean mEnableMic = true;

    private boolean mEnableTorch = false;

    private int mSelectedBeauty = 0;

    private int mSelectedFilter = 0;

    protected boolean mHaveLoginedChannel = false;

    private boolean mHostHasBeenCalled = false;

    private ZegoAVKitCommon.ZegoCameraCaptureRotation mZegoCameraCaptureRotation = ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_0;

    private DisplayManager.DisplayListener mDisplayListener;

    private PhoneStateListener mPhoneStateListener;

    protected abstract void doLiveBusinessAfterLoginChannel();

    protected abstract void afterPlayingSuccess(String streamID);

    protected abstract void afterPlayingStop(String streamID);

    protected abstract void afterPublishingSuccess(String streamID);

    protected abstract void afterPublishingStop(String streamID);


    @Override
    protected int getContentViewLayout() {
        return R.layout.activity_live;
    }


    @Override
    protected void initExtraData(Bundle savedInstanceState) {
        if (savedInstanceState != null) {
            // Activity 后台被回收后重新启动, 恢复数据
            mChannel = PreferenceUtil.getInstance().getStringValue(KEY_CHANNEL, null);
            mPublishTitle = PreferenceUtil.getInstance().getStringValue(KEY_PUBLISH_TITLE, null);
            mPublishStreamID = PreferenceUtil.getInstance().getStringValue(KEY_PUBLISH_STREAM_ID, null);
            mEnableFrontCam = PreferenceUtil.getInstance().getBooleanValue(KEY_ENABLE_FRONT_CAM, false);
            mEnableTorch = PreferenceUtil.getInstance().getBooleanValue(KEY_ENABLE_TORCH, false);
            mEnableMic = PreferenceUtil.getInstance().getBooleanValue(KEY_ENABLE_MIC, false);
            mEnableCamera = PreferenceUtil.getInstance().getBooleanValue(KEY_ENABLE_CAMERA, false);
            mHaveLoginedChannel = PreferenceUtil.getInstance().getBooleanValue(KEY_HAVE_LOGINNED_CHANNEL, false);
            mSelectedBeauty = PreferenceUtil.getInstance().getIntValue(KEY_SELECTED_BEAUTY, 0);
            mSelectedFilter = PreferenceUtil.getInstance().getIntValue(KEY_SELECTED_FILTER, 0);

            mListLiveViewTag = (List<String>) PreferenceUtil.getInstance().getObjectFromString(KEY_LIST_LIVEVIEW_TAG);
            if (mListLiveViewTag == null) {
                mListLiveViewTag = new ArrayList<>();
            }

            mListLog = (LinkedList<String>) PreferenceUtil.getInstance().getObjectFromString(KEY_LIST_LOG);
            if (mListLog == null) {
                mListLog = new LinkedList<>();
            }

            mZegoCameraCaptureRotation = (ZegoAVKitCommon.ZegoCameraCaptureRotation) PreferenceUtil.getInstance().getObjectFromString(KEY_CAMERA_CAPTURE_ROTATION);
        }
    }


    @Override
    protected void initVariables(final Bundle savedInstanceState) {

        mZegoAVKit = ZegoApiManager.getInstance().getZegoAVKit();
        mMapFreeViewIndex = new LinkedHashMap<>();
        mMapFreeViewIndex.put(ZegoAVKitCommon.ZegoRemoteViewIndex.First, EMPTY_STREAM_ID);
        mMapFreeViewIndex.put(ZegoAVKitCommon.ZegoRemoteViewIndex.Second, EMPTY_STREAM_ID);
        mMapFreeViewIndex.put(ZegoAVKitCommon.ZegoRemoteViewIndex.Third, EMPTY_STREAM_ID);

        // 初始化sdk回调
        initCallback();
        // 初始化电话监听器
        initPhoneCallingListener();
        // 初始化屏幕旋转
        initRotationListener();
    }

    /**
     * 初始化设置面板.
     */
    private void initSettingPannel() {

        PublishSettingsPannel settingsPannel = (PublishSettingsPannel) findViewById(R.id.publishSettingsPannel);
        settingsPannel.initPublishSettings(mEnableCamera, mEnableFrontCam, mEnableMic, mEnableTorch, mSelectedBeauty, mSelectedFilter);
        settingsPannel.setPublishSettingsCallback(new PublishSettingsPannel.PublishSettingsCallback() {
            @Override
            public void onEnableCamera(boolean isEnable) {
                mEnableCamera = isEnable;
                mZegoAVKit.enableCamera(isEnable);
            }

            @Override
            public void onEnableFrontCamera(boolean isEnable) {
                mEnableFrontCam = isEnable;
                mZegoAVKit.setFrontCam(isEnable);
                if (mZegoCameraCaptureRotation != null) {
                    mZegoAVKit.setDisplayRotation(mZegoCameraCaptureRotation);
                }
            }

            @Override
            public void onEnableMic(boolean isEnable) {
                mEnableMic = isEnable;
                mZegoAVKit.enableMic(isEnable);
            }

            @Override
            public void onEnableTorch(boolean isEnable) {
                mEnableTorch = isEnable;
                mZegoAVKit.enableTorch(isEnable);
            }

            @Override
            public void onSetBeauty(int beauty) {
                mSelectedBeauty = beauty;
                mZegoAVKit.enableBeautifying(ZegoAVKitUtil.getZegoBeauty(beauty));
            }

            @Override
            public void onSetFilter(int filter) {
                mSelectedFilter = filter;
                mZegoAVKit.setFilter(ZegoAVKitUtil.getZegoFilter(filter));
            }
        });

        mBehavior = BottomSheetBehavior.from(settingsPannel);
        FrameLayout flytMainContent = (FrameLayout) findViewById(R.id.main_content);
        if (flytMainContent != null) {
            flytMainContent.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (mBehavior.getState() == BottomSheetBehavior.STATE_EXPANDED) {
                        mBehavior.setState(BottomSheetBehavior.STATE_COLLAPSED);
                    }
                }
            });
        }
    }

    @Override
    protected void initViews(Bundle savedInstanceState) {

        mRlytControlHeader = (RelativeLayout) findViewById(R.id.rlyt_control_header);

        initSettingPannel();

        mTvMainMsg = (TextView) findViewById(R.id.tv_main_msg);
        mTvSubMsg = (TextView) findViewById(R.id.tv_sub_msg);


        final ViewLive vlBigView = (ViewLive) findViewById(R.id.vl_big_view);
        if (vlBigView != null) {
            mListViewLive.add(vlBigView);
        }

        final ViewLive vlSmallView1 = (ViewLive) findViewById(R.id.vl_small_view1);
        if (vlSmallView1 != null) {
            vlSmallView1.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    vlSmallView1.toFullScreen(vlBigView, mZegoAVKit);
                }
            });
            mListViewLive.add(vlSmallView1);
        }

        final ViewLive vlSmallView2 = (ViewLive) findViewById(R.id.vl_small_view2);
        if (vlSmallView2 != null) {
            vlSmallView2.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    vlSmallView2.toFullScreen(vlBigView, mZegoAVKit);
                }
            });
            mListViewLive.add(vlSmallView2);
        }
    }

    @Override
    protected void doBusiness(Bundle savedInstanceState) {
        if(savedInstanceState != null){
            replayAndRepublish();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();

        // 保存数据, 用于Activity在后台被回收后重新恢复
        PreferenceUtil.getInstance().setStringValue(KEY_CHANNEL, mChannel);
        PreferenceUtil.getInstance().setStringValue(KEY_PUBLISH_TITLE, mPublishTitle);
        PreferenceUtil.getInstance().setStringValue(KEY_PUBLISH_STREAM_ID, mPublishStreamID);
        PreferenceUtil.getInstance().setBooleanValue(KEY_ENABLE_CAMERA, mEnableCamera);
        PreferenceUtil.getInstance().setBooleanValue(KEY_ENABLE_FRONT_CAM, mEnableFrontCam);
        PreferenceUtil.getInstance().setBooleanValue(KEY_ENABLE_TORCH, mEnableTorch);
        PreferenceUtil.getInstance().setBooleanValue(KEY_ENABLE_MIC, mEnableMic);
        PreferenceUtil.getInstance().setBooleanValue(KEY_HAVE_LOGINNED_CHANNEL, mHaveLoginedChannel);
        PreferenceUtil.getInstance().setIntValue(KEY_SELECTED_BEAUTY, mSelectedBeauty);
        PreferenceUtil.getInstance().setIntValue(KEY_SELECTED_FILTER, mSelectedFilter);

        PreferenceUtil.getInstance().setObjectToString(KEY_LIST_LOG, mListLog);

        mListLiveViewTag = new ArrayList<>();
        for (int i = 0, size = mListViewLive.size(); i < size; i++) {
            mListLiveViewTag.add(mListViewLive.get(i).getLiveTag());
        }
        PreferenceUtil.getInstance().setObjectToString(KEY_LIST_LIVEVIEW_TAG, mListLiveViewTag);

        PreferenceUtil.getInstance().setObjectToString(KEY_CAMERA_CAPTURE_ROTATION, mZegoCameraCaptureRotation);
    }

    /**
     * 初始化屏幕旋转监听器.
     */
    protected void initRotationListener() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            mDisplayListener = new DisplayManager.DisplayListener() {
                @Override
                public void onDisplayAdded(int displayId) {
                }

                @Override
                public void onDisplayChanged(int displayId) {
                    changeRotation();
                }

                @Override
                public void onDisplayRemoved(int displayId) {
                }
            };

            DisplayManager displayManager = (DisplayManager) getSystemService(Context.DISPLAY_SERVICE);
            displayManager.registerDisplayListener(mDisplayListener, mHandler);
        } else {
            changeRotation();
        }
    }

    /**
     * activity重建后, 恢复发布与播放.
     */
    protected void replayAndRepublish() {

        for (int i = 0, size = mListLiveViewTag.size(); i < size; i++) {
            int streamOrdinal = ViewLive.getStreamOrdinalFromLiveTag(mListLiveViewTag.get(i));
            String streamID = ViewLive.getStreamIDFromLiveTag(mListLiveViewTag.get(i));
            switch (streamOrdinal) {
                case 0:
                case 1:
                case 2:
                    startPlay(streamID, ZegoAVKitUtil.getZegoRemoteViewIndexByOrdinal(streamOrdinal));
                    break;
                case ViewLive.PUBLISH_STREAM_ORDINAL:
                    startPublish();
                    break;
            }
        }
    }

    /**
     * 挂断电话后, 恢复发布与播放.
     */
    protected void replayAndRepublishAfterRingOff() {
        for (int i = 0, size = mListLiveViewTagForCallComing.size(); i < size; i++) {
            int streamOrdinal = ViewLive.getStreamOrdinalFromLiveTag(mListLiveViewTagForCallComing.get(i));
            String streamID = ViewLive.getStreamIDFromLiveTag(mListLiveViewTagForCallComing.get(i));
            switch (streamOrdinal) {
                case 0:
                case 1:
                case 2:
                    startPlay(streamID, ZegoAVKitUtil.getZegoRemoteViewIndexByOrdinal(streamOrdinal));
                    break;
                case ViewLive.PUBLISH_STREAM_ORDINAL:
                    BizLivePresenter.getInstance().createStreamInPrivateRoom(mPublishTitle, mPublishStreamID);
                    break;
            }
        }
    }


    /**
     * 获取空闲的remoteViewIndex.
     *
     * @return
     */
    protected ZegoAVKitCommon.ZegoRemoteViewIndex getFreeZegoRemoteViewIndex() {
        ZegoAVKitCommon.ZegoRemoteViewIndex freeIndex = null;
        for (ZegoAVKitCommon.ZegoRemoteViewIndex index : mMapFreeViewIndex.keySet()) {
            if (EMPTY_STREAM_ID.equals(mMapFreeViewIndex.get(index))) {
                freeIndex = index;
                break;
            }
        }
        return freeIndex;
    }

    /**
     * 获取空闲的View用于播放或者发布.
     *
     * @return
     */
    protected ViewLive getFreeViewLive() {
        ViewLive vlFreeView = null;
        for (int i = 0, size = mListViewLive.size(); i < size; i++) {
            ViewLive viewLive = mListViewLive.get(i);
            if (viewLive.isFree()) {
                vlFreeView = viewLive;
                vlFreeView.setVisibility(View.VISIBLE);
                break;
            }
        }
        return vlFreeView;
    }

    /**
     * 释放View用于再次播放, 释放remoteViewIndex.
     *
     * @param streamID
     */
    protected void releaseTextureViewAndRemoteViewIndex(String streamID) {
        for (int i = 0, size = mListViewLive.size(); i < size; i++) {
            ViewLive currentViewLive = mListViewLive.get(i);
            if (currentViewLive.getStreamID().equals(streamID)) {
                int j = i;
                for (; j < size - 1; j++) {
                    ViewLive nextViewLive = mListViewLive.get(j + 1);
                    if (nextViewLive.isFree()) {
                        break;
                    }

                    int nextStreamOrdinal = nextViewLive.getStreamOrdinal();
                    switch (nextStreamOrdinal) {
                        case 0:
                        case 1:
                        case 2:
                            mZegoAVKit.setRemoteView(ZegoAVKitUtil.getZegoRemoteViewIndexByOrdinal(nextStreamOrdinal), currentViewLive.getTextureView());
                            break;
                        case ViewLive.PUBLISH_STREAM_ORDINAL:
                            mZegoAVKit.setLocalView(currentViewLive.getTextureView());
                            break;
                    }
                    currentViewLive.setLiveTag(nextViewLive.getLiveTag());
                    currentViewLive.setLiveQuality(nextViewLive.getLiveQuality());
                    currentViewLive = nextViewLive;
                }
                // 标记最后一个View可用
                mListViewLive.get(j).setFree();
                break;
            }
        }

        for (ZegoAVKitCommon.ZegoRemoteViewIndex index : mMapFreeViewIndex.keySet()) {
            if (mMapFreeViewIndex.get(index).equals(streamID)) {
                // 标记remoteViewIndex可用
                mMapFreeViewIndex.put(index, EMPTY_STREAM_ID);
                break;
            }
        }
    }


    /**
     * 初始化zego sdk回调.
     */
    protected void initCallback() {

        mZegoAVKit.setZegoLiveCallback(new ZegoLiveCallback() {
            @Override
            public void onLoginChannel(String channel, int retCode) {
                if (retCode == 0) {
                    printLog(getString(R.string.myself, getString(R.string.login_channel_success, channel)));

                    if (!mHaveLoginedChannel) {
                        mHaveLoginedChannel = true;

                        doLiveBusinessAfterLoginChannel();
                    }

                    if (mHostHasBeenCalled) {
                        mHostHasBeenCalled = false;
                        // 挂断电话重新恢复
                        replayAndRepublishAfterRingOff();
                    }

                } else {
                    printLog(getString(R.string.myself, getString(R.string.login_channel_failed, channel, retCode + "")));
                }
            }

            @Override
            public void onPublishSucc(String streamID, String liveChannel, HashMap<String, Object> info) {
                mRlytControlHeader.bringToFront();

                printLog(getString(R.string.myself, getString(R.string.publish_stream_success, streamID)));

                afterPublishingSuccess(streamID);
            }

            @Override
            public void onPublishStop(int retCode, String streamID, String liveChannel) {
                // 停止预览
                mZegoAVKit.stopPreview();
                // 释放View
                releaseTextureViewAndRemoteViewIndex(streamID);

                mRlytControlHeader.bringToFront();

                printLog(getString(R.string.myself, getString(R.string.publish_stream_failed, streamID, retCode + "")));


                afterPublishingStop(streamID);
            }

            @Override
            public void onMixStreamConfigUpdate(int i, String s, HashMap<String, Object> hashMap) {

            }

            @Override
            public void onPlaySucc(String streamID, String liveChannel) {
                mRlytControlHeader.bringToFront();

                // 记录流ID用于play失败后重新play
                mMapReplayStreamID.put(streamID, false);

                printLog(getString(R.string.myself, getString(R.string.play_stream_success, streamID)));

                afterPlayingSuccess(streamID);
            }

            @Override
            public void onPlayStop(int retCode, String streamID, String liveChannel) {
                // 释放View
                releaseTextureViewAndRemoteViewIndex(streamID);
                mRlytControlHeader.bringToFront();

                // 当一条流play失败后重新play一次
                if (retCode == 2 && !TextUtils.isEmpty(streamID)) {
                    if (!mMapReplayStreamID.get(streamID)) {
                        mMapReplayStreamID.put(streamID, true);
                        startPlay(streamID, getFreeZegoRemoteViewIndex());
                    }
                }

                printLog(getString(R.string.myself, getString(R.string.play_stream_failed, streamID, retCode + "")));

                afterPlayingStop(streamID);
            }

            @Override
            public void onVideoSizeChanged(String streamID, int width, int height) {
            }

            @Override
            public void onTakeRemoteViewSnapshot(final Bitmap bitmap, ZegoAVKitCommon.ZegoRemoteViewIndex zegoRemoteViewIndex) {
            }

            @Override
            public void onTakeLocalViewSnapshot(final Bitmap bitmap) {
            }

            @Override
            public void onCaptureVideoSize(int width, int height) {
            }


            @Override
            public void onPlayQualityUpdate(String streamID, int quality, double videoFPS, double videoBitrate) {
                setLiveQuality(streamID, quality);

            }

            @Override
            public void onPublishQulityUpdate(String streamID, int quality, double videoFPS, double videoBitrate) {
                setLiveQuality(streamID, quality);
            }

            @Override
            public AuxData onAuxCallback(int i) {
                return null;
            }
        });

    }

    private void setLiveQuality(String streamID, int quality) {
        if (TextUtils.isEmpty(streamID)) {
            return;
        }
        for (ViewLive vl : mListViewLive) {
            if (streamID.equals(vl.getStreamID())) {
                vl.setLiveQuality(quality);
                break;
            }
        }
    }

    /**
     * 电话状态监听.
     */
    protected void initPhoneCallingListener() {
        mPhoneStateListener = new PhoneStateListener() {
            @Override
            public void onCallStateChanged(int state, String incomingNumber) {
                super.onCallStateChanged(state, incomingNumber);
                switch (state) {
                    case TelephonyManager.CALL_STATE_IDLE:
                        if (mHostHasBeenCalled) {
                            // 登陆频道
                            ZegoUser zegoUser = new ZegoUser(PreferenceUtil.getInstance().getUserID(), PreferenceUtil.getInstance().getUserName());
                            mZegoAVKit.loginChannel(zegoUser, mChannel);
                        }

                        break;
                    case TelephonyManager.CALL_STATE_RINGING:
                        mHostHasBeenCalled = true;
                        mListLiveViewTagForCallComing = new ArrayList<>();
                        for (int i = 0, size = mListViewLive.size(); i < size; i++) {
                            mListLiveViewTagForCallComing.add(mListViewLive.get(i).getLiveTag());
                        }
                        // 来电停止发布与播放
                        stopAllStreamAndLogout();
                        break;

                    case TelephonyManager.CALL_STATE_OFFHOOK:
                        break;
                }
            }
        };

        TelephonyManager tm = (TelephonyManager) getSystemService(Service.TELEPHONY_SERVICE);
        tm.listen(mPhoneStateListener, PhoneStateListener.LISTEN_CALL_STATE);
    }


    /**
     * 开始发布.
     */
    protected void startPublish() {

        ViewLive freeViewLive = getFreeViewLive();
        if (freeViewLive == null) {
            return;
        }

        // 标记view已经被占用
        freeViewLive.setLiveTag(ViewLive.PUBLISH_STREAM_ORDINAL, mPublishStreamID);

        // 输出发布状态
        printLog(getString(R.string.myself, getString(R.string.start_to_publish_stream, mPublishStreamID)));

        // 设置美颜 滤镜
        mZegoAVKit.enableBeautifying(ZegoAVKitUtil.getZegoBeauty(mSelectedBeauty));
        mZegoAVKit.setFilter(ZegoAVKitUtil.getZegoFilter(mSelectedFilter));

        // 开始播放
        mZegoAVKit.setLocalView(freeViewLive.getTextureView());
        mZegoAVKit.setLocalViewMode(ZegoAVKitCommon.ZegoVideoViewMode.ScaleAspectFill);
        mZegoAVKit.startPreview();
        mZegoAVKit.startPublish(mPublishTitle, mPublishStreamID);

        mZegoAVKit.setFrontCam(mEnableFrontCam);
        mZegoAVKit.enableTorch(mEnableTorch);
        mZegoAVKit.enableMic(mEnableMic);
    }

    protected void stopPublish() {
        mZegoAVKit.stopPreview();
        mZegoAVKit.stopPublish();
        mZegoAVKit.setLocalView(null);

        printLog(getString(R.string.myself, getString(R.string.stop_publising_stream, mPublishStreamID)));
    }

    protected boolean isStreamExisted(String streamID) {
        boolean isExisted = false;
        for (String value : mMapFreeViewIndex.values()) {
            if (value.equals(streamID)) {
                isExisted = true;
                break;
            }
        }
        return isExisted;
    }

    /**
     * 开始播放流.
     */
    protected void startPlay(String streamID, ZegoAVKitCommon.ZegoRemoteViewIndex remoteViewIndex) {

        if (isStreamExisted(streamID)) {
            return;
        }

        if (remoteViewIndex == null) {
            return;
        }

        ViewLive freeViewLive = getFreeViewLive();
        if (freeViewLive == null) {
            return;
        }

        // 标记remoteViewIndex已经被占用
        mMapFreeViewIndex.put(remoteViewIndex, streamID);

        // 标记view已经被占用
        freeViewLive.setLiveTag(remoteViewIndex.code, streamID);

        // 输出播放状态
        printLog(getString(R.string.myself, getString(R.string.start_to_play_stream, streamID)));


        // 播放
        mZegoAVKit.setRemoteViewMode(remoteViewIndex, ZegoAVKitCommon.ZegoVideoViewMode.ScaleAspectFill);
        mZegoAVKit.setRemoteView(remoteViewIndex, freeViewLive.getTextureView());
        mZegoAVKit.startPlayStream(streamID, remoteViewIndex);
    }

    protected void stopPlay(String streamID) {
        for (ZegoAVKitCommon.ZegoRemoteViewIndex index : mMapFreeViewIndex.keySet()) {
            if (mMapFreeViewIndex.get(index).equals(streamID)) {
                mZegoAVKit.stopPlayStream(streamID);
                mZegoAVKit.setRemoteView(index, null);

                printLog(getString(R.string.myself, getString(R.string.stop_playing_stream, streamID)));
                break;
            }
        }
    }

    /**
     * 根据屏幕的旋转角度旋转用于play或者publish的TextureView.
     */
    protected void changeRotation() {
        switch (getWindowManager().getDefaultDisplay().getRotation()) {
            case Surface.ROTATION_0:
                mZegoAVKit.setDisplayRotation(ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_0);
                mZegoCameraCaptureRotation = ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_0;
                break;
            case Surface.ROTATION_90:
                mZegoAVKit.setDisplayRotation(ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_90);
                mZegoCameraCaptureRotation = ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_90;
                break;
            case Surface.ROTATION_180:
                mZegoAVKit.setDisplayRotation(ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_180);
                mZegoCameraCaptureRotation = ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_180;
                break;
            case Surface.ROTATION_270:
                mZegoAVKit.setDisplayRotation(ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_270);
                mZegoCameraCaptureRotation = ZegoAVKitCommon.ZegoCameraCaptureRotation.Rotate_270;
                break;
        }
    }


    protected void logout() {
        AlertDialog dialog = new AlertDialog.Builder(this).setMessage(getString(R.string.do_you_really_want_to_leave_the_chat_room)).setTitle(getString(R.string.hint)).setPositiveButton(getString(R.string.Yes), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                stopAllStreamAndLogout();
                dialog.dismiss();
                finish();
            }
        }).setNegativeButton(getString(R.string.No), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        }).create();

        dialog.show();
    }

    /**
     * 退出.
     */
    protected void stopAllStreamAndLogout() {

        for (int i = 0, size = mListViewLive.size(); i < size; i++) {
            switch (mListViewLive.get(i).getStreamOrdinal()) {
                case 0:
                case 1:
                case 2:
                    stopPlay(mListViewLive.get(i).getStreamID());
                    break;
                case ViewLive.PUBLISH_STREAM_ORDINAL:
                    stopPublish();
                    break;
            }


        }

        mZegoAVKit.logoutChannel();

    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            if (mBehavior.getState() == BottomSheetBehavior.STATE_EXPANDED) {
                mBehavior.setState(BottomSheetBehavior.STATE_COLLAPSED);
                return false;
            } else {
                // 退出
                logout();
            }

        }
        return super.onKeyDown(keyCode, event);
    }

    @OnClick(R.id.tv_log_list)
    public void openLogList() {
        LogListActivity.actionStart(this);
    }

    @OnClick(R.id.tv_publish_settings)
    public void publishSettings() {
        if (mBehavior.getState() == BottomSheetBehavior.STATE_COLLAPSED) {
            mBehavior.setState(BottomSheetBehavior.STATE_EXPANDED);
        } else {
            mBehavior.setState(BottomSheetBehavior.STATE_COLLAPSED);
        }
    }

    @OnClick(R.id.tv_close)
    public void close() {
        logout();
    }


    protected void printLog(String msg) {
        mListLog.addFirst(msg);
    }

    public void showMainMsg(String msg){
        mTvMainMsg.setText(msg);
    }

    public void showSubMsg(String msg){
        mTvSubMsg.setText(msg);
    }

    @Override
    protected void onDestroy() {
        // 注销屏幕监听
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            DisplayManager displayManager = (DisplayManager) getSystemService(Context.DISPLAY_SERVICE);
            displayManager.unregisterDisplayListener(mDisplayListener);
            mDisplayListener = null;
        }

        // 注销电话监听
        TelephonyManager tm = (TelephonyManager) getSystemService(Service.TELEPHONY_SERVICE);
        tm.listen(mPhoneStateListener, PhoneStateListener.LISTEN_NONE);
        mPhoneStateListener = null;

        // 清空回调, 避免内存泄漏
        mZegoAVKit.setZegoLiveCallback(null);

        super.onDestroy();
    }


}
