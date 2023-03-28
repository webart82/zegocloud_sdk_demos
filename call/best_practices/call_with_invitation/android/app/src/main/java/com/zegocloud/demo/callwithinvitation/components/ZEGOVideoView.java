package com.zegocloud.demo.callwithinvitation.components;

import android.content.Context;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.view.TextureView;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.zegocloud.demo.callwithinvitation.ZEGOSDKManager;
import com.zegocloud.demo.callwithinvitation.internal.ExpressService;
import com.zegocloud.demo.callwithinvitation.utils.ToastUtil;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

import im.zego.zegoexpress.constants.ZegoRemoteDeviceState;
import im.zego.zegoexpress.constants.ZegoUpdateType;
import im.zego.zegoexpress.constants.ZegoViewMode;
import im.zego.zegoexpress.entity.ZegoStream;

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
    private ExpressService expressService;
    private ZegoViewMode zegoViewMode = ZegoViewMode.ASPECT_FILL;

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
        expressService = ZEGOSDKManager.getInstance().expressService;
    }

    public TextureView getTextureView() {
        return textureView;
    }

    public void startPreviewOnly() {
        ZEGOSDKManager.getInstance().startCameraPreview(textureView, zegoViewMode);
    }

    public void setUserID(String userID) {
        this.mUserID = userID;
        startAudioVideo();
    }

    public String getUserID() {
        return mUserID;
    }

    public void startAudioVideo() {
        if (TextUtils.isEmpty(mUserID)) {
            return;
        }
        if (expressService.isLocalUser(mUserID)) {
            ZEGOSDKManager.getInstance().startCameraPreview(textureView, zegoViewMode);
            ZEGOSDKManager.getInstance().startPublishLocalAudioVideo();
        } else {
            String streamID = expressService.generateStream(mUserID);
            ZEGOSDKManager.getInstance().startPlayRemoteAudioVideo(textureView, streamID, zegoViewMode);
        }
    }

    public void stopAudioVideo() {
        if (TextUtils.isEmpty(mUserID)) {
            return;
        }
        if (expressService.isLocalUser(mUserID)) {
            ZEGOSDKManager.getInstance().stopCameraPreview();
            ZEGOSDKManager.getInstance().stopPublishLocalAudioVideo();
        } else {
            String streamID = expressService.generateStream(mUserID);
            ZEGOSDKManager.getInstance().stopPlayRemoteAudioVideo(streamID);
        }
    }

    public void onRoomStreamUpdate(String roomID, ZegoUpdateType updateType, ArrayList<ZegoStream> streamList,
        JSONObject extendedData) {
        for (ZegoStream stream : streamList) {
            if (TextUtils.isEmpty(mUserID)) {
                mUserID = stream.user.userID;
            }
            ToastUtil.show(getContext(), "receive " + stream.user.userName + "'s stream " + updateType);
            if (stream.user.userID.equals(mUserID)) {
                if (updateType == ZegoUpdateType.ADD) {
                    ZEGOSDKManager.getInstance().startPlayRemoteAudioVideo(textureView, stream.streamID, zegoViewMode);
                } else {
                    ZEGOSDKManager.getInstance().stopPlayRemoteAudioVideo(stream.streamID);
                }
                break;
            }
        }
    }

    public void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
        String mStreamID = expressService.generateStream(mUserID);
        if (Objects.equals(streamID, mStreamID)) {

        }
    }

    public void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
        String mStreamID = expressService.generateStream(mUserID);
        if (Objects.equals(mStreamID, streamID)) {

        }
    }
}
