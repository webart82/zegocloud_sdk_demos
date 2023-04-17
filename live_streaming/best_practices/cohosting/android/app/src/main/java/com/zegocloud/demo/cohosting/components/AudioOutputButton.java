package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.util.AttributeSet;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;

public class AudioOutputButton extends ZEGOImageButton {

    public AudioOutputButton(@NonNull Context context) {
        super(context);
    }

    public AudioOutputButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public AudioOutputButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void initView() {
        super.initView();
        setImageResource(R.drawable.call_icon_speaker, R.drawable.call_icon_built_in);
    }

    @Override
    public void open() {
        super.open();
        ZEGOSDKManager.getInstance().rtcService.audioRouteToSpeaker(true);
    }

    @Override
    public void close() {
        super.close();
        ZEGOSDKManager.getInstance().rtcService.audioRouteToSpeaker(false);
    }
}
