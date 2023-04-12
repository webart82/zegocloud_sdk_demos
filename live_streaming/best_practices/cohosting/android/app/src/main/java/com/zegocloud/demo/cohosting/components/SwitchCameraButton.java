package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.util.AttributeSet;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;

public class SwitchCameraButton extends ZEGOImageButton {

    public SwitchCameraButton(@NonNull Context context) {
        super(context);
    }

    public SwitchCameraButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public SwitchCameraButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void initView() {
        super.initView();
        setImageResource(R.drawable.call_icon_camera_flip);
    }

    @Override
    protected void afterClick() {
        super.afterClick();
        toggle();
    }

    @Override
    public void open() {
        super.open();
        ZEGOSDKManager.getInstance().rtcService.useFrontCamera(true);
    }

    @Override
    public void close() {
        super.close();
        ZEGOSDKManager.getInstance().rtcService.useFrontCamera(false);
    }
}
