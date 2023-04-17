package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.util.AttributeSet;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;

public class ToggleCameraButton extends ZEGOImageButton {

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
    public void open() {
        super.open();
        ZEGOSDKManager.getInstance().rtcService.enableCamera(true);
    }

    @Override
    public void close() {
        super.close();
        ZEGOSDKManager.getInstance().rtcService.enableCamera(false);
    }
}
