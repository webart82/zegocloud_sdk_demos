package com.zegocloud.demo.cohosting.internal;

import android.app.Application;
import android.view.TextureView;
import com.zegocloud.demo.cohosting.utils.LogUtil;
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
import java.util.ArrayList;
import java.util.Objects;
import org.json.JSONObject;

public class ZEGOExpressService {

    private ZegoExpressEngine engine;
    private ZegoUser localUser;
    private String currentRoomID;
    private boolean isPreview = false;
    private IZegoEventHandler eventHandler;
    private RoomStateChangeListener roomStateChangeListener;

    public void initSDK(Application application, long appID, String appSign) {
        if (engine != null) {
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
        engine = ZegoExpressEngine.createEngine(profile, new IZegoEventHandler() {

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
                if (roomStateChangeListener != null) {
                    roomStateChangeListener.onRoomStateChanged(roomID, reason, errorCode, extendedData);
                }
            }
        });
    }

    public void startCameraPreview(TextureView textureView, ZegoViewMode viewMode) {
        LogUtil.d("startCameraPreview() called with: textureView = [" + textureView + "]");
        if (engine == null) {
            return;
        }
        ZegoCanvas canvas = new ZegoCanvas(textureView);
        canvas.viewMode = viewMode;
        engine.startPreview(canvas);
        isPreview = true;
    }

    public void stopCameraPreview() {
        LogUtil.d("stopCameraPreview() called");
        if (engine == null) {
            return;
        }
        if (isPreview) {
            engine.stopPreview();
        }
        isPreview = false;
    }

    public String generateStream(String userID) {
        return currentRoomID + "_" + userID;
    }

    /**
     * preview before publish
     */
    public void startPublishLocalAudioVideo() {
        if (engine == null || localUser == null) {
            return;
        }
        String streamID = generateStream(localUser.userID);
        LogUtil.d("startPublishLocalVideo() called: " + streamID);
        engine.startPublishingStream(streamID);
    }

    public void stopPublishLocalAudioVideo() {
        if (engine == null) {
            return;
        }
        engine.stopPublishingStream();
    }

    public void startPlayRemoteAudioVideo(TextureView textureView, String streamID, ZegoViewMode viewMode) {
        LogUtil.d(
            "startPlayRemoteAudioVideo() called with: textureView = [" + textureView + "], streamID = [" + streamID
                + "]");
        if (engine == null) {
            return;
        }
        ZegoCanvas canvas = new ZegoCanvas(textureView);
        canvas.viewMode = viewMode;
        engine.startPlayingStream(streamID, canvas);
    }

    public void stopPlayRemoteAudioVideo(String streamID) {
        if (engine == null) {
            return;
        }
        engine.stopPlayingStream(streamID);
    }

    public void setEventHandler(IZegoEventHandler eventHandler) {
        this.eventHandler = eventHandler;
    }

    public void joinRoom(String roomID, IZegoRoomLoginCallback callback) {
        if (engine == null || localUser == null) {
            return;
        }
        ZegoRoomConfig config = new ZegoRoomConfig();
        config.isUserStatusNotify = true;
        engine.loginRoom(roomID, localUser, config, new IZegoRoomLoginCallback() {
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
        if (engine == null) {
            return;
        }
        engine.logoutRoom();
        currentRoomID = null;
    }

    public void connectUser(String userID, String userName) {
        localUser = new ZegoUser(userID, userName);
    }

    public void disConnectUser() {
        localUser = null;
    }

    public ZegoUser getUserInfo() {
        return localUser;
    }

    public void enableCamera(boolean enable) {
        if (engine == null) {
            return;
        }
        engine.enableCamera(enable);
    }

    public void openMicrophone(boolean open) {
        if (engine == null) {
            return;
        }
        engine.muteMicrophone(!open);
    }

    public void useFrontCamera(boolean useFront) {
        if (engine == null) {
            return;
        }
        engine.useFrontCamera(useFront);
    }

    public void audioRouteToSpeaker(boolean routeToSpeaker) {
        if (engine == null) {
            return;
        }
        engine.setAudioRouteToSpeaker(routeToSpeaker);
    }

    public boolean isLocalUser(String userID) {
        if (localUser != null) {
            return Objects.equals(userID, localUser.userID);
        } else {
            return false;
        }
    }

    public void enableCustomVideoProcessing(boolean enable, ZegoCustomVideoProcessConfig config,
        ZegoPublishChannel channel) {
        if (engine == null) {
            return;
        }
        engine.enableCustomVideoProcessing(enable, config, channel);
    }

    public void setCustomVideoProcessHandler(IZegoCustomVideoProcessHandler handler) {
        if (engine == null) {
            return;
        }
        engine.setCustomVideoProcessHandler(handler);
    }

    public ZegoVideoConfig getVideoConfig() {
        if (engine == null) {
            return null;
        }
        return engine.getVideoConfig();
    }

    public void sendCustomVideoProcessedTextureData(int textureID, int width, int height,
        long referenceTimeMillisecond) {
        if (engine == null) {
            return;
        }
        engine.sendCustomVideoProcessedTextureData(textureID, width, height, referenceTimeMillisecond);
    }

    public void setRoomStateChangeListener(RoomStateChangeListener roomStateChangeListener) {
        this.roomStateChangeListener = roomStateChangeListener;
    }

    public interface RoomStateChangeListener {

        void onRoomStateChanged(String roomID, ZegoRoomStateChangedReason reason, int errorCode,
            JSONObject extendedData);
    }
}