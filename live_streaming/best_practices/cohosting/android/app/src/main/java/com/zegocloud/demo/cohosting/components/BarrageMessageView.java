package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.IMBarrageMessageListener;
import im.zego.zegoexpress.entity.ZegoBarrageMessageInfo;
import java.util.ArrayList;

public class BarrageMessageView extends FrameLayout {

    public BarrageMessageView(@NonNull Context context) {
        super(context);
        initView();
    }

    public BarrageMessageView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public BarrageMessageView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    public BarrageMessageView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr,
        int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView();
    }

    private void initView() {
        ZEGOSDKManager.getInstance().rtcService.addBarrageMessageListener(new IMBarrageMessageListener() {
            @Override
            public void onIMRecvBarrageMessage(String roomID, ArrayList<ZegoBarrageMessageInfo> messageList) {

            }
        });
    }
}
