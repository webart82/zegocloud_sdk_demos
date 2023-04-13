package com.zegocloud.demo.callwithinvitation.internal;

import android.app.Application;
import android.view.TextureView;

import com.zegocloud.demo.callwithinvitation.utils.LogUtil;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoCustomVideoProcessHandler;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zegoexpress.constants.ZegoPublishChannel;
import im.zego.zegoexpress.constants.ZegoRemoteDeviceState;
import im.zego.zegoexpress.constants.ZegoRoomStateChangedReason;
import im.zego.zegoexpress.constants.ZegoScenario;
import im.zego.zegoexpress.constants.ZegoUpdateType;
import im.zego.zegoexpress.constants.ZegoViewMode;
import im.zego.zegoexpress.entity.ZegoCanvas;
import im.zego.zegoexpress.entity.ZegoCustomVideoProcessConfig;
import im.zego.zegoexpress.entity.ZegoEngineConfig;
import im.zego.zegoexpress.entity.ZegoEngineProfile;
import im.zego.zegoexpress.entity.ZegoRoomConfig;
import im.zego.zegoexpress.entity.ZegoStream;
import im.zego.zegoexpress.entity.ZegoUser;
import im.zego.zegoexpress.entity.ZegoVideoConfig;

public class ExpressService {

    private ZegoExpressEngine express;
    private ZegoUser localUser;
    private String currentRoomID;
    private boolean isPreview = false;
    private IZegoEventHandler eventHandler;

    public void initSDK(Application application, long appID, String appSign) {
        if (express != null) {
            return;
        }
        ZegoEngineProfile profile = new ZegoEngineProfile();
        profile.appID = appID;
        profile.appSign = appSign;
        profile.scenario = ZegoScenario.DEFAULT;
        profile.application = application;
        ZegoEngineConfig config = new ZegoEngineConfig();
        config.advancedConfig.put("notify_remote_device_unknown_status", "true");
        config.advancedConfig.put("notify_remote_device_init_status", "true");
        ZegoExpressEngine.setEngineConfig(config);
        express = ZegoExpressEngine.createEngine(profile, new IZegoEventHandler() {

            @Override
            public void onRoomStreamUpdate(String roomID, ZegoUpdateType updateType, ArrayList<ZegoStream> streamList,
                JSONObject extendedData) {
                super.onRoomStreamUpdate(roomID, updateType, streamList, extendedData);
                LogUtil.d("onRoomStreamUpdate() called with: roomID = [" + roomID + "], updateType = [" + updateType
                    + "], streamList = [" + streamList + "], extendedData = [" + extendedData + "]");
                if (eventHandler != null) {
                    eventHandler.onRoomStreamUpdate(roomID, updateType, streamList, extendedData);
                }
            }

            @Override
            public void onRoomUserUpdate(String roomID, ZegoUpdateType updateType, ArrayList<ZegoUser> userList) {
                super.onRoomUserUpdate(roomID, updateType, userList);
                if (eventHandler != null) {
                    eventHandler.onRoomUserUpdate(roomID, updateType, userList);
                }
            }

            @Override
            public void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
                super.onRemoteCameraStateUpdate(streamID, state);
                LogUtil.d(
                    "onRemoteCameraStateUpdate() called with: streamID = [" + streamID + "], state = [" + state + "]");
                if (eventHandler != null) {
                    eventHandler.onRemoteCameraStateUpdate(streamID, state);
                }
            }

            @Override
            public void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
                super.onRemoteMicStateUpdate(streamID, state);
                if (eventHandler != null) {
                    eventHandler.onRemoteMicStateUpdate(streamID, state);
                }
            }

            @Override
            public void onRoomStateChanged(String roomID, ZegoRoomStateChangedReason reason, int errorCode,
                JSONObject extendedData) {
                super.onRoomStateChanged(roomID, reason, errorCode, extendedData);
                LogUtil.d("onRoomStateChanged() called with: roomID = [" + roomID + "], reason = [" + reason
                    + "], errorCode = [" + errorCode + "], extendedData = [" + extendedData + "]");
                if (eventHandler != null) {
                    eventHandler.onRoomStateChanged(roomID, reason, errorCode, extendedData);
                }
            }
        });
    }

    public void startCameraPreview(TextureView textureView, ZegoViewMode viewMode) {
        LogUtil.d("startCameraPreview() called with: textureView = [" + textureView + "]");
        if (express == null) {
            return;
        }
        ZegoCanvas canvas = new ZegoCanvas(textureView);
        canvas.viewMode = viewMode;
        express.startPreview(canvas);
        isPreview = true;
    }

    public void stopCameraPreview() {
        LogUtil.d("stopCameraPreview() called");
        if (express == null) {
            return;
        }
        if (isPreview) {
            express.stopPreview();
        }
        isPreview = false;
    }

    public String generateStream(String userID) {
        return currentRoomID + "_" + userID;
    }

    /**
     *  preview before publish
     */
    public void startPublishLocalVideo() {
        if (express == null || localUser == null) {
            return;
        }
        String streamID = generateStream(localUser.userID);
        LogUtil.d("startPublishLocalVideo() called: " + streamID);
        express.startPublishingStream(streamID);
    }

    public void stopPublishLocalVideo() {
        if (express == null) {
            return;
        }
        express.stopPublishingStream();
    }

    public void startPlayRemoteAudioVideo(TextureView textureView, String streamID, ZegoViewMode viewMode) {
        LogUtil.d(
            "startPlayRemoteAudioVideo() called with: textureView = [" + textureView + "], streamID = [" + streamID
                + "]");
        if (express == null) {
            return;
        }
        ZegoCanvas canvas = new ZegoCanvas(textureView);
        canvas.viewMode = viewMode;
        express.startPlayingStream(streamID, canvas);
    }

    public void stopPlayRemoteAudioVideo(String streamID) {
        if (express == null) {
            return;
        }
        express.stopPlayingStream(streamID);
    }

    public void setEventHandler(IZegoEventHandler eventHandler) {
        this.eventHandler = eventHandler;
    }

    public void joinRoom(String roomID, IZegoRoomLoginCallback callback) {
        if (express == null || localUser == null) {
            return;
        }
        ZegoRoomConfig config = new ZegoRoomConfig();
        config.isUserStatusNotify = true;
        express.loginRoom(roomID, localUser, config, new IZegoRoomLoginCallback() {
            @Override
            public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                LogUtil.d(
                    "onRoomLoginResult() called with: errorCode = [" + errorCode + "], extendedData = [" + extendedData
                        + "]");
                if (errorCode == 0) {
                    currentRoomID = roomID;
                }
                if (callback != null) {
                    callback.onRoomLoginResult(errorCode, extendedData);
                }
            }
        });
    }

    public void leaveRoom() {
        if (express == null) {
            return;
        }
        express.logoutRoom();
        currentRoomID = null;
    }

    public void connectUser(String userID, String userName) {
        localUser = new ZegoUser(userID, userName);
    }

    public void disconnectUser() {
        localUser = null;
    }

    public ZegoUser getUserInfo() {
        return localUser;
    }

    public void enableCamera(boolean enable) {
        if (express == null) {
            return;
        }
        express.enableCamera(enable);
    }

    public void openMicrophone(boolean open) {
        if (express == null) {
            return;
        }
        express.muteMicrophone(!open);
    }

    public void useFrontCamera(boolean useFront) {
        if (express == null) {
            return;
        }
        express.useFrontCamera(useFront);
    }

    public void audioRouteToSpeaker(boolean routeToSpeaker) {
        if (express == null) {
            return;
        }
        express.setAudioRouteToSpeaker(routeToSpeaker);
    }

    public boolean isLocalUser(String userID) {
        if (localUser != null) {
            return Objects.equals(userID, localUser.userID);
        } else {
            return false;
        }
    }

    public ZegoVideoConfig getVideoConfig() {
        if (express == null) {
            return null;
        }
        return express.getVideoConfig();
    }

}
