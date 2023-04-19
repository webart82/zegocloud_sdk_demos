package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.Log;
import android.view.TextureView;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import im.zego.zegoexpress.constants.ZegoViewMode;
import java.util.Objects;

/**
 * if mUserID is set to local,will preview camera and publish.
 * <p>
 * if mUserID is set to others,will play his stream when he published success
 * <p>
 * if mUserID is not set,will auto play first receive user's stream or used to preview camera only
 */
public class ZEGOVideoView extends FrameLayout {

    private String mUserID;
    private TextureView textureView;
    private ZEGOExpressService rtcService;
    private ZegoViewMode zegoViewMode = ZegoViewMode.ASPECT_FILL;
    private boolean start = false;

    public ZEGOVideoView(@NonNull Context context) {
        super(context);
        initView();
    }

    public ZEGOVideoView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public ZEGOVideoView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    private void initView() {
        textureView = new TextureView(getContext());
        addView(textureView);
        rtcService = ZEGOSDKManager.getInstance().rtcService;
    }

    public TextureView getTextureView() {
        return textureView;
    }

    public void startPreviewOnly() {
        ZEGOSDKManager.getInstance().rtcService.startCameraPreview(textureView, zegoViewMode);
    }

    private static final String TAG = "ZEGOVideoView";

    public void setUserID(String userID) {
        Log.d(TAG, "setUserID() called with: userID = [" + userID + "]");
        if (Objects.equals(mUserID, userID) && start) {
            return;
        }
        this.mUserID = userID;
        if (!TextUtils.isEmpty(mUserID)) {
            startAudioVideo();
        } else {
            stopAudioVideo();
        }
    }

    public String getUserID() {
        return mUserID;
    }

    public void startAudioVideo() {
        if (TextUtils.isEmpty(mUserID)) {
            return;
        }
        start = true;
        if (rtcService.isLocalUser(mUserID)) {
            ZEGOSDKManager.getInstance().rtcService.startCameraPreview(textureView, zegoViewMode);
            ZEGOSDKManager.getInstance().rtcService.startPublishLocalAudioVideo();
        } else {
            ZEGOLiveUser userInfo = rtcService.getUser(mUserID);
            if (userInfo != null) {
                String streamID = rtcService.generateStream(mUserID);
                ZEGOSDKManager.getInstance().rtcService.startPlayRemoteAudioVideo(textureView, streamID, zegoViewMode);
            }
        }
    }

    public void stopAudioVideo() {
        if (TextUtils.isEmpty(mUserID)) {
            return;
        }
        start = false;
        if (rtcService.isLocalUser(mUserID)) {
            ZEGOSDKManager.getInstance().rtcService.stopCameraPreview();
            ZEGOSDKManager.getInstance().rtcService.stopPublishLocalAudioVideo();
        } else {
            String streamID = rtcService.generateStream(mUserID);
            ZEGOSDKManager.getInstance().rtcService.stopPlayRemoteAudioVideo(streamID);
        }
    }
}
