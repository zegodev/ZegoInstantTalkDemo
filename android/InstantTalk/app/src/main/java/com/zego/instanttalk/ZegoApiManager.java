package com.zego.instanttalk;


import android.content.Context;

import com.zego.zegoavkit2.ZegoAVKit;
import com.zego.zegoavkit2.ZegoAvConfig;

/**
 * des: zego api管理器.
 */
public class ZegoApiManager {


    private static ZegoApiManager sInstance = null;

    private ZegoAVKit mZegoAVKit = null;

    private ZegoAvConfig mZegoAvConfig = null;

    private ZegoApiManager() {
        mZegoAVKit = new ZegoAVKit();
    }

    public static ZegoApiManager getInstance() {
        if (sInstance == null) {
            synchronized (ZegoApiManager.class) {
                if (sInstance == null) {
                    sInstance = new ZegoApiManager();
                }
            }
        }
        return sInstance;
    }

    /**
     * 初始化sdk.
     */
    public void initSDK(Context context) {

        // 设置日志level
        mZegoAVKit.setLogLevel(context, ZegoAVKit.LOG_LEVEL_DEBUG, null);

        // type=2 用于视频聊天
        mZegoAVKit.setBusinessType(2);

        /**
         * 请开发者联系 ZEGO support 获取各自业务的 AppID 与 signKey
         * AppID 填写样式示例：1234567890L
         * signKey 填写样式示例：new byte[] { (byte) 0x00, (byte) 0x01, (byte) 0x02, (byte) 0x03, (byte) 0x04, (byte) 0x05, (byte) 0x06, (byte) 0x07,
                (byte) 0x08, (byte) 0x09,  (byte) 0x00, (byte) 0x01, (byte) 0x02, (byte) 0x03, (byte) 0x04, (byte) 0x05, (byte) 0x06, (byte) 0x07,
                (byte) 0x08, (byte) 0x09, (byte) 0x00, (byte) 0x01, (byte) 0x02, (byte) 0x03, (byte) 0x04, (byte) 0x05, (byte) 0x06, (byte) 0x07,
                (byte) 0x08, (byte) 0x09,  (byte) 0x00, (byte) 0x01};
        **/

        byte[] signKey = ;
        int appID = ;

        // 初始化sdk
        mZegoAVKit.init(appID, signKey, context);

        // 初始化设置级别为"High"
        mZegoAvConfig = new ZegoAvConfig(ZegoAvConfig.Level.High);
        mZegoAVKit.setAVConfig(mZegoAvConfig);
    }


    /**
     * 释放sdk.
     */
    public void releaseSDK() {
        mZegoAVKit.unInit();
        mZegoAVKit = null;
        sInstance = null;
    }

    public ZegoAVKit getZegoAVKit() {
        return mZegoAVKit;
    }

    public void setZegoConfig(ZegoAvConfig config) {
        mZegoAvConfig = config;
        mZegoAVKit.setAVConfig(config);
    }
}
