package com.zegocloud.demo.callwithinvitation.components;

import android.content.Context;
import android.util.AttributeSet;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.zegocloud.demo.callwithinvitation.R;
import com.zegocloud.demo.callwithinvitation.ZEGOSDKManager;

public class ToggleMicrophoneButton extends CallImageButton {

    public ToggleMicrophoneButton(@NonNull Context context) {
        super(context);
    }

    public ToggleMicrophoneButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public ToggleMicrophoneButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void initView() {
        super.initView();
        setImageResource(R.drawable.call_icon_mic_on, R.drawable.call_icon_mic_off);
    }

    @Override
    protected void afterClick() {
        super.afterClick();
        toggle();
    }

    @Override
    public void open() {
        super.open();
        ZEGOSDKManager.getInstance().openMicrophone(true);
    }

    @Override
    public void close() {
        super.close();
        ZEGOSDKManager.getInstance().openMicrophone(false);
    }

    @Override
    public void setState(boolean state) {
        super.setState(state);
        ZEGOSDKManager.getInstance().openMicrophone(state);
    }
}
