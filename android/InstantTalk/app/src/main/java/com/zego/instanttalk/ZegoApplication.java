package com.zego.instanttalk;

import android.app.Application;
import android.content.Context;

import com.zego.instanttalk.presenters.BizLivePresenter;


/**
 * des: 自定义Application.
 */
public class ZegoApplication extends Application{

    public static Context sApplicationContext;


    @Override
    public void onCreate() {
        super.onCreate();

        sApplicationContext = this;

        BizLivePresenter.getInstance();
        ZegoApiManager.getInstance().initSDK(this);
    }

    /**
     * 获取Application Context.
     *
     * @return Application Context
     */
    public Context getApplicationContext(){
        return sApplicationContext;
    }

}
