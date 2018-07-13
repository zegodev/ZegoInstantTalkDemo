package com.zego.instanttalk.ui.fragments;

import android.content.Context;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.zego.instanttalk.R;
import com.zego.instanttalk.ZegoApiManager;
import com.zego.instanttalk.ZegoApplication;
import com.zego.instanttalk.presenters.UserListPresenter;
import com.zego.instanttalk.ui.base.AbsBaseFragment;
import com.zego.instanttalk.presenters.BizLivePresenter;
import com.zego.instanttalk.ui.acivities.AboutZegoActivity;
import com.zego.instanttalk.utils.BizLiveUitl;
import com.zego.instanttalk.utils.PreferenceUtil;
import com.zego.zegoavkit2.ZegoAvConfig;

import butterknife.Bind;
import butterknife.OnClick;


/**
 * des: 设置页面.
 */
public class SettingFragment extends AbsBaseFragment {


    @Bind(R.id.tv_sdk_version)
    public TextView tvsdkVersion;

    @Bind(R.id.et_user_account)
    public EditText etUserAccount;

    @Bind(R.id.et_user_name)
    public EditText etUserName;

    @Bind(R.id.iv_avatar)
    public ImageView ivAvatar;

    @Bind(R.id.sp_resolutions)
    public Spinner spinnerResolutions;

    @Bind(R.id.tv_resolution)
    public TextView tvResolution;

    @Bind(R.id.sb_resolution)
    public SeekBar seekbarResolution;

    @Bind(R.id.tv_fps)
    public TextView tvFps;

    @Bind(R.id.sb_fps)
    public SeekBar seekBarFps;

    @Bind(R.id.tv_bitrate)
    public TextView tvBitrate;

    @Bind(R.id.sb_bitrate)
    public SeekBar seekBarBitrate;

    @Bind(R.id.llyt_hide_operation)
    public LinearLayout llytHideOperation;

    @Bind(R.id.tb_modify_test_env)
    public ToggleButton tbTestEnv;

    @Bind(R.id.et_appid)
    public EditText etAppID;

    @Bind(R.id.et_appkey)
    public EditText etAppKey;

    @Bind(R.id.sv)
    public ScrollView scrollView;

    @Bind(R.id.tv_modify_video_configs)
    public TextView tvModifyVideConfigs;

    @Bind(R.id.tv_modify_appid_and_appsign)
    public TextView tvModifyAppIDAndAppSign;

    private boolean mIsFirstIn = true;

    // 分辨率text
    private String mResolutionTexts[];

    public static SettingFragment newInstance(){
        return new SettingFragment();
    }

    @Override
    protected int getContentViewLayout() {
        return R.layout.fragment_setting;
    }

    @Override
    protected void initExtraData() {

    }

    @Override
    protected void initVariables() {
        mResolutionTexts = mResources.getStringArray(R.array.resolutions);
    }

    @Override
    protected void initViews() {

        tvsdkVersion.setText(ZegoApiManager.getInstance().getZegoAVKit().version());

        etUserAccount.setText(PreferenceUtil.getInstance().getUserID());
        etUserName.setText(PreferenceUtil.getInstance().getUserName());

        etUserName.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                /*判断是否是“Done”键*/
                if(actionId == EditorInfo.IME_ACTION_DONE){

                    String userName = etUserName.getText().toString().trim();
                    if(TextUtils.isEmpty(userName)){
                        Toast.makeText(mParentActivity, getString(R.string.user_name_can_not_be_empty), Toast.LENGTH_SHORT).show();
                    }else {

                        PreferenceUtil.getInstance().setUserName(userName);

                        /*隐藏软键盘*/
                        InputMethodManager imm = (InputMethodManager) v
                                .getContext().getSystemService(
                                        Context.INPUT_METHOD_SERVICE);
                        if (imm.isActive()) {
                            imm.hideSoftInputFromWindow(
                                    v.getApplicationWindowToken(), 0);
                        }

                        // 退出大厅, 重新登陆
                        BizLivePresenter.getInstance().leavePublicRoom();
                    }

                    return true;
                }
                return false;
            }
        });

        ivAvatar.setImageBitmap(BizLiveUitl.getAvatarByUserID(PreferenceUtil.getInstance().getUserID()));

        final SeekBar.OnSeekBarChangeListener seekBarChangeListener = new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                switch (seekBar.getId()) {
                    case R.id.sb_resolution:
                        tvResolution.setText(getString(R.string.resolution_prefix, mResolutionTexts[progress]));
                        break;
                    case R.id.sb_fps:
                        tvFps.setText(getString(R.string.fps_prefix, progress + ""));
                        break;
                    case R.id.sb_bitrate:
                        tvBitrate.setText(getString(R.string.bitrate_prefix, progress + ""));
                        break;
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                spinnerResolutions.setSelection(ZegoAvConfig.LEVEL_COUNT - 1);
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        };

        // 默认设置级别为"高"
        final ZegoAvConfig.Level defaultLevel = ZegoAvConfig.Level.High;
        // 初始化分辨率, 默认为640x480
        seekbarResolution.setMax(ZegoAvConfig.MAX_LEVEL);
        seekbarResolution.setProgress(defaultLevel.code);
        seekbarResolution.setOnSeekBarChangeListener(seekBarChangeListener);
        tvResolution.setText(getString(R.string.resolution_prefix, mResolutionTexts[defaultLevel.code]));

        // 初始化帧率, 默认为15
        seekBarFps.setMax(ZegoAvConfig.MAX_VIDEO_FPS);
        seekBarFps.setProgress(15);
        seekBarFps.setOnSeekBarChangeListener(seekBarChangeListener);
        tvFps.setText(getString(R.string.fps_prefix, 15 + ""));

        // 初始化码率, 默认为600 * 1000
        seekBarBitrate.setMax(ZegoAvConfig.MAX_VIDEO_BITRATE);
        seekBarBitrate.setProgress(ZegoAvConfig.VIDEO_BITRATES[defaultLevel.code]);
        seekBarBitrate.setOnSeekBarChangeListener(seekBarChangeListener);
        tvBitrate.setText(getString(R.string.bitrate_prefix, ZegoAvConfig.VIDEO_BITRATES[defaultLevel.code] + ""));

        spinnerResolutions.setSelection(defaultLevel.code);
        spinnerResolutions.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (position <= ZegoAvConfig.MAX_LEVEL) {
                    int level = position;
                    seekbarResolution.setProgress(level);
                    // 预设级别中,帧率固定为"15"
                    seekBarFps.setProgress(15);
                    seekBarBitrate.setProgress(ZegoAvConfig.VIDEO_BITRATES[level]);
                }
                if(position < ZegoAvConfig.MAX_LEVEL){
                    seekbarResolution.setEnabled(false);
                    seekBarFps.setEnabled(false);
                    seekBarBitrate.setEnabled(false);
                }else {
                    seekbarResolution.setEnabled(true);
                    seekBarFps.setEnabled(true);
                    seekBarBitrate.setEnabled(true);
                }

                if(!mIsFirstIn){
                    tvModifyVideConfigs.setVisibility(View.VISIBLE);
                }else {
                    mIsFirstIn = false;
                }

            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        tbTestEnv.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {
                    ZegoApiManager.getInstance().getZegoAVKit().setTestEnv(true);
                } else {
                    ZegoApiManager.getInstance().getZegoAVKit().setTestEnv(false);
                }
            }
        });

        seekbarResolution.setEnabled(false);
        seekBarFps.setEnabled(false);
        seekBarBitrate.setEnabled(false);
    }

    @Override
    protected void loadData() {

    }

    @OnClick(R.id.tv_switch_avatar)
    public void switchAvatar(){
        String userID = BizLiveUitl.generateUserID();
        String userName = BizLiveUitl.generateUserName(userID);

        PreferenceUtil.getInstance().setUserID(userID);
        PreferenceUtil.getInstance().setUserName(userName);

        etUserAccount.setText(userID);
        etUserName.setText(userName);

        ivAvatar.setImageBitmap(BizLiveUitl.getAvatarByUserID(userID));

        // 退出大厅, 重新登陆
        BizLivePresenter.getInstance().leavePublicRoom();
    }

    @OnClick(R.id.rlyt_advanced)
    public void showAdvaaced(){
        llytHideOperation.setVisibility(View.VISIBLE);
        tvModifyAppIDAndAppSign.setVisibility(View.VISIBLE);
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                scrollView.fullScroll(ScrollView.FOCUS_DOWN);
            }
        });
    }


    @OnClick(R.id.tv_upload_log)
    public void uploadLog(){
        ZegoApiManager.getInstance().getZegoAVKit().uploadLog();
        mHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(mParentActivity, R.string.upload_log_successfully, Toast.LENGTH_SHORT).show();
            }
        }, 2000);
    }

    @OnClick(R.id.tv_about)
    public void openAboutPage(){
        AboutZegoActivity.actionStart(mParentActivity);
    }

    @OnClick(R.id.tv_modify_video_configs)
    public void modifyVideoConfigs() {

        InputMethodManager imm = (InputMethodManager) mParentActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(mParentActivity.getCurrentFocus().getWindowToken(), InputMethodManager.HIDE_NOT_ALWAYS);

        ZegoAvConfig zegoAvConfig = null;
        switch (spinnerResolutions.getSelectedItemPosition()) {
            case 0:
                zegoAvConfig = new ZegoAvConfig(ZegoAvConfig.Level.VeryLow);
                break;
            case 1:
                zegoAvConfig = new ZegoAvConfig(ZegoAvConfig.Level.Low);
                break;
            case 2:
                zegoAvConfig = new ZegoAvConfig(ZegoAvConfig.Level.Generic);
                break;
            case 3:
                zegoAvConfig = new ZegoAvConfig(ZegoAvConfig.Level.High);
                break;
            case 4:
                zegoAvConfig = new ZegoAvConfig(ZegoAvConfig.Level.VeryHigh);
                break;
            case 5:
                // 自定义设置
                zegoAvConfig = new ZegoAvConfig();
                zegoAvConfig.setResolution(ZegoAvConfig.VIDEO_RESOLUTIONS[seekbarResolution.getProgress()][0], ZegoAvConfig.VIDEO_RESOLUTIONS[seekbarResolution.getProgress()][1]);
                zegoAvConfig.setVideoFPS(seekBarFps.getProgress());
                zegoAvConfig.setVideoBitrate(seekBarBitrate.getProgress());
                break;
        }

        if (zegoAvConfig != null) {
            ZegoApiManager.getInstance().setZegoConfig(zegoAvConfig);
        }

        Toast.makeText(mParentActivity, getString(R.string.modify_video_configs_successfully), Toast.LENGTH_SHORT).show();
    }

    @OnClick(R.id.tv_modify_appid_and_appsign)
    public void modifyAppIDAndAppSign(){
        // 设置appID appKey
        final String appID = etAppID.getText().toString().trim();
        final String appKey = etAppKey.getText().toString().trim();
        new Thread(new Runnable() {
            @Override
            public void run() {
                if (!TextUtils.isEmpty(appID) && !TextUtils.isEmpty(appKey)) {
                    // appID必须是数字
                    if (!TextUtils.isDigitsOnly(appID)) {
                        return;
                    }
                    // appKey长度必须等于32位
                    String[] keys = appKey.split(",");
                    if (keys.length != 32) {
                        return;
                    }

                    byte[] signKey = new byte[32];
                    for (int i = 0; i < 32; i++) {
                        int data = Integer.valueOf(keys[i].trim().replace("0x", ""), 16);
                        signKey[i] = (byte) data;
                    }

                    ZegoApiManager.getInstance().getZegoAVKit().unInit();
                    ZegoApiManager.getInstance().getZegoAVKit().init(Long.valueOf(appID), signKey, ZegoApplication.sApplicationContext);

                    // 即构分配的key与id
                    byte[] signKeyBiz = {
                            (byte)0xf9,(byte)0xe4,(byte)0x7b,(byte)0x67,(byte)0xa,(byte)0x8f,(byte)0x46,
                            (byte)0x14,(byte)0x3e,(byte)0xdb,(byte)0xfb,(byte)0xc0,(byte)0x66,(byte)0x2a,
                            (byte)0xc4,(byte)0xfe,(byte)0x88,(byte)0xde,(byte)0xb6,(byte)0x3f,(byte)0x79,
                            (byte)0xad,(byte)0xc5,(byte)0xc4,(byte)0xe3,(byte)0xa6,(byte)0x18,(byte)0x1b,
                            (byte)0x7d,(byte)0xe3,(byte)0x1e,(byte)0x91
                    };
                    long appIDBiz = 308895348;

                    BizLivePresenter.getInstance().uninit();
                    BizLivePresenter.getInstance().init(appIDBiz, signKeyBiz, signKeyBiz.length, ZegoApplication.sApplicationContext);

                    mHandler.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            Toast.makeText(mParentActivity, getString(R.string.modify_appid_and_appsign_successfully), Toast.LENGTH_SHORT).show();
                            // 退出大厅, 重新登陆
                            UserListPresenter.getInstance().clearUserList();
                            BizLivePresenter.getInstance().leavePublicRoom();
                        }
                    }, 1000);
                }
            }
        }).start();
    }
}
