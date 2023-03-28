package com.zegocloud.demo.callwithinvitation.components;

import android.content.Context;
import android.util.AttributeSet;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.zegocloud.demo.callwithinvitation.R;
import com.zegocloud.demo.callwithinvitation.ZEGOSDKManager;

public class ToggleCameraButton extends CallImageButton {

    public ToggleCameraButton(@NonNull Context context) {
        super(context);
    }

    public ToggleCameraButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public ToggleCameraButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void initView() {
        super.initView();
        setImageResource(R.drawable.call_icon_camera_on, R.drawable.call_icon_camera_off);
    }

    @Override
    protected void afterClick() {
        super.afterClick();
        toggle();
    }

    @Override
    public void open() {
        super.open();
        ZEGOSDKManager.getInstance().enableCamera(true);
    }

    @Override
    public void close() {
        super.close();
        ZEGOSDKManager.getInstance().enableCamera(false);
    }

    @Override
    public void setState(boolean state) {
        super.setState(state);
        ZEGOSDKManager.getInstance().enableCamera(state);
    }
}
