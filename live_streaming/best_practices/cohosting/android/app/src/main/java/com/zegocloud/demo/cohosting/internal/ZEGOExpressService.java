package com.zegocloud.demo.cohosting.internal;

import android.app.Application;
import android.text.TextUtils;
import android.util.Log;
import android.view.TextureView;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.LogUtil;
import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoCustomVideoProcessHandler;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.callback.IZegoIMSendBarrageMessageCallback;
import im.zego.zegoexpress.callback.IZegoIMSendCustomCommandCallback;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zegoexpress.constants.ZegoPublishChannel;
import im.zego.zegoexpress.constants.ZegoPublisherState;
import im.zego.zegoexpress.constants.ZegoRemoteDeviceState;
import im.zego.zegoexpress.constants.ZegoRoomStateChangedReason;
import im.zego.zegoexpress.constants.ZegoScenario;
import im.zego.zegoexpress.constants.ZegoUpdateType;
import im.zego.zegoexpress.constants.ZegoViewMode;
import im.zego.zegoexpress.entity.ZegoBarrageMessageInfo;
import im.zego.zegoexpress.entity.ZegoCanvas;
import im.zego.zegoexpress.entity.ZegoCustomVideoProcessConfig;
import im.zego.zegoexpress.entity.ZegoEngineConfig;
import im.zego.zegoexpress.entity.ZegoEngineProfile;
import im.zego.zegoexpress.entity.ZegoRoomConfig;
import im.zego.zegoexpress.entity.ZegoStream;
import im.zego.zegoexpress.entity.ZegoUser;
import im.zego.zegoexpress.entity.ZegoVideoConfig;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.json.JSONObject;

public class ZEGOExpressService {

    private ZegoExpressEngine engine;
    private ZEGOLiveUser localUser;
    private ZEGOLiveUser hostUser;
    private String currentRoomID;
    private Map<String, ZEGOLiveUser> roomUserMap = new HashMap<>();
    private RoomStateChangeListener roomStateChangeListener;

    private IZegoEventHandler eventHandler;
    private List<RoomUserChangeListener> roomUserChangeListenerList = new ArrayList<>();
    private List<RoomStreamChangeListener> roomStreamChangeListenerList = new ArrayList<>();
    private List<IMCustomCommandListener> customCommandListenerList = new ArrayList<>();
    private List<IMBarrageMessageListener> barrageMessageListenerList = new ArrayList<>();

    // order by default time s
    private List<String> userIDList = new ArrayList<>();
    private List<String> videoUserIDList = new ArrayList<>();

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
                List<ZEGOLiveUser> userList = new ArrayList<>();
                if (updateType == ZegoUpdateType.ADD) {
                    for (ZegoStream zegoStream : streamList) {
                        ZEGOLiveUser liveUser = getUser(zegoStream.user.userID);
                        if (liveUser == null) {
                            liveUser = new ZEGOLiveUser(zegoStream.user.userID, zegoStream.user.userName);
                            saveUserInfo(liveUser);
                        }
                        liveUser.setStreamID(zegoStream.streamID);
                        if (!TextUtils.isEmpty(liveUser.getMainStreamID())) {
                            if (liveUser.isHost()) {
                                if (videoUserIDList.isEmpty()) {
                                    videoUserIDList.add(zegoStream.user.userID);
                                } else {
                                    videoUserIDList.remove(zegoStream.user.userID);
                                    videoUserIDList.set(0, zegoStream.user.userID);
                                }
                                hostUser = liveUser;
                            } else {
                                videoUserIDList.add(liveUser.userID);
                            }
                        }
                        userList.add(liveUser);
                    }
                    for (RoomStreamChangeListener listener : roomStreamChangeListenerList) {
                        listener.onStreamAdd(userList);
                    }
                } else {

                    for (ZegoStream zegoStream : streamList) {
                        ZEGOLiveUser liveUser = getUser(zegoStream.user.userID);
                        if (liveUser != null) {
                            liveUser.deleteStream(zegoStream.streamID);
                            if (hostUser != null && hostUser.equals(liveUser)) {
                                hostUser = null;
                            }
                        }
                        videoUserIDList.remove(zegoStream.user.userID);
                    }
                    for (RoomStreamChangeListener listener : roomStreamChangeListenerList) {
                        listener.onStreamRemove(userList);
                    }
                }

                if (eventHandler != null) {
                    eventHandler.onRoomStreamUpdate(roomID, updateType, streamList, extendedData);
                }
            }

            @Override
            public void onPublisherStateUpdate(String streamID, ZegoPublisherState state, int errorCode,
                JSONObject extendedData) {
                super.onPublisherStateUpdate(streamID, state, errorCode, extendedData);
                Log.d(TAG, "onPublisherStateUpdate() called with: streamID = [" + streamID + "], state = [" + state
                    + "], errorCode = [" + errorCode + "], extendedData = [" + extendedData + "]");
                localUser.setStreamID(streamID);

                ArrayList<ZegoStream> streamList = new ArrayList<>(1);
                ZegoStream zegoStream = new ZegoStream();
                zegoStream.user = new ZegoUser(localUser.userID, localUser.userName);
                zegoStream.streamID = streamID;
                zegoStream.extraInfo = extendedData.toString();
                streamList.add(zegoStream);

                if (state == ZegoPublisherState.PUBLISHING) {
                    for (RoomStreamChangeListener listener : roomStreamChangeListenerList) {
                        listener.onStreamAdd(Collections.singletonList(localUser));
                    }
                    if (eventHandler != null) {
                        eventHandler.onRoomStreamUpdate(currentRoomID, ZegoUpdateType.ADD, streamList, extendedData);
                    }
                } else if (state == ZegoPublisherState.NO_PUBLISH) {
                    for (RoomStreamChangeListener listener : roomStreamChangeListenerList) {
                        listener.onStreamRemove(Collections.singletonList(localUser));
                    }
                    if (eventHandler != null) {
                        eventHandler.onRoomStreamUpdate(currentRoomID, ZegoUpdateType.DELETE, streamList, extendedData);
                    }
                }

            }

            @Override
            public void onRoomUserUpdate(String roomID, ZegoUpdateType updateType, ArrayList<ZegoUser> userList) {
                super.onRoomUserUpdate(roomID, updateType, userList);
                Log.d(TAG, "onRoomUserUpdate() called with: roomID = [" + roomID + "], updateType = [" + updateType
                    + "], userList = [" + userList + "]");
                List<ZEGOLiveUser> liveUserList = new ArrayList<>();
                for (ZegoUser zegoUser : userList) {
                    ZEGOLiveUser liveUser = getUser(zegoUser.userID);
                    if (liveUser != null) {
                        liveUserList.add(liveUser);
                    } else {
                        liveUserList.add(new ZEGOLiveUser(zegoUser.userID, zegoUser.userName));
                    }
                }

                if (updateType == ZegoUpdateType.ADD) {
                    for (ZEGOLiveUser liveUser : liveUserList) {
                        saveUserInfo(liveUser);
                    }
                    for (RoomUserChangeListener listener : roomUserChangeListenerList) {
                        listener.onUserEnter(liveUserList);
                    }
                } else {
                    for (ZEGOLiveUser liveUser : liveUserList) {
                        removeUserInfo(liveUser.userID);
                    }
                    for (RoomUserChangeListener listener : roomUserChangeListenerList) {
                        listener.onUserLeft(liveUserList);
                    }
                }

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

            @Override
            public void onIMRecvCustomCommand(String roomID, ZegoUser fromUser, String command) {
                super.onIMRecvCustomCommand(roomID, fromUser, command);
                Log.d(TAG, "onIMRecvCustomCommand() called with: roomID = [" + roomID + "], fromUser = [" + fromUser
                    + "], command = [" + command + "]");
                for (IMCustomCommandListener listener : customCommandListenerList) {
                    listener.onIMRecvCustomCommand(roomID, fromUser, command);
                }
                if (eventHandler != null) {
                    eventHandler.onIMRecvCustomCommand(roomID, fromUser, command);
                }
            }

            @Override
            public void onIMRecvBarrageMessage(String roomID, ArrayList<ZegoBarrageMessageInfo> messageList) {
                super.onIMRecvBarrageMessage(roomID, messageList);
                Log.d(TAG,
                    "onIMRecvBarrageMessage() called with: roomID = [" + roomID + "], messageList = [" + messageList
                        + "]");
                for (IMBarrageMessageListener listener : barrageMessageListenerList) {
                    listener.onIMRecvBarrageMessage(roomID, messageList);
                }
                if (eventHandler != null) {
                    eventHandler.onIMRecvBarrageMessage(roomID, messageList);
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
    }

    public void stopCameraPreview() {
        LogUtil.d("stopCameraPreview() called");
        if (engine == null) {
            return;
        }
        engine.stopPreview();
    }

    public String generateStream(String userID) {
        ZEGOLiveUser userInfo = getUser(userID);
        String streamID;
        if (userInfo.isHost()) {
            streamID = currentRoomID + "_" + userID + "_main" + "_host";
        } else {
            streamID = currentRoomID + "_" + userID + "_main" + "_cohost";
        }
        return streamID;
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
        currentRoomID = roomID;
        ZegoRoomConfig config = new ZegoRoomConfig();
        config.isUserStatusNotify = true;
        ZegoUser zegoUser = new ZegoUser(localUser.userID, localUser.userName);
        engine.loginRoom(roomID, zegoUser, config, new IZegoRoomLoginCallback() {
            @Override
            public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                LogUtil.d(
                    "onRoomLoginResult() called with: errorCode = [" + errorCode + "], extendedData = [" + extendedData
                        + "]");
                if (errorCode != 0) {
                    currentRoomID = null;
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
        roomUserMap.clear();
        userIDList.clear();
        videoUserIDList.clear();
        roomUserChangeListenerList.clear();
        roomStreamChangeListenerList.clear();
        currentRoomID = null;
    }

    public void connectUser(String userID, String userName) {
        localUser = new ZEGOLiveUser(userID, userName);
    }

    public void disConnectUser() {
        localUser = null;
    }

    public ZEGOLiveUser getLocalUser() {
        return localUser;
    }

    public ZEGOLiveUser getHostUser() {
        return hostUser;
    }

    private void saveUserInfo(ZEGOLiveUser liveUser) {
        Log.d(TAG, "saveUserInfo() called with: liveUser = [" + liveUser + "]");
        boolean contains = roomUserMap.containsKey(liveUser.userID);
        roomUserMap.put(liveUser.userID, liveUser);

        if (contains) {
            userIDList.remove(liveUser.userID);
        }
        userIDList.add(liveUser.userID);
    }

    private void removeUserInfo(String userID) {
        Log.d(TAG, "removeUserInfo() called with: userID = [" + userID + "]");
        roomUserMap.remove(userID);
        userIDList.remove(userID);
    }

    public List<ZEGOLiveUser> getUserList() {
        List<ZEGOLiveUser> userList = new ArrayList<>();
        userList.add(localUser);
        for (String userID : userIDList) {
            ZEGOLiveUser liveUser = roomUserMap.get(userID);
            userList.add(liveUser);
        }
        return userList;
    }

    public List<ZEGOLiveUser> getVideoUserList() {
        List<ZEGOLiveUser> userList = new ArrayList<>();
        if (localUser.hasStream()) {
            userList.add(localUser);
        }
        for (String userID : videoUserIDList) {
            ZEGOLiveUser liveUser = roomUserMap.get(userID);
            userList.add(liveUser);
        }
        return userList;
    }

    public ZEGOLiveUser getUser(String userID) {
        if (userID != null && localUser != null && userID.equals(localUser.userID)) {
            return localUser;
        }
        return roomUserMap.get(userID);
    }

    private static final String TAG = "ZEGOExpressService";

    public void enableCamera(boolean enable) {
        Log.d(TAG, "enableCamera() called with: enable = [" + enable + "]");
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

    public void sendCustomCommand(String command, ArrayList<ZegoUser> toUserList,
        IZegoIMSendCustomCommandCallback callback) {
        Log.d(TAG, "sendCustomCommand() called with: command = [" + command + "], toUserList = [" + toUserList
            + "], callback = [" + callback + "]");
        if (engine == null) {
            return;
        }
        engine.sendCustomCommand(currentRoomID, command, toUserList, callback);
    }

    public void sendBarrageMessage(String message, IZegoIMSendBarrageMessageCallback callback) {
        if (engine == null) {
            return;
        }
        engine.sendBarrageMessage(currentRoomID, message, new IZegoIMSendBarrageMessageCallback() {
            @Override
            public void onIMSendBarrageMessageResult(int errorCode, String messageID) {
                if (callback != null) {
                    callback.onIMSendBarrageMessageResult(errorCode, messageID);
                }
                for (IMBarrageMessageListener listener : barrageMessageListenerList) {
                    listener.onIMSendBarrageMessageResult(errorCode, message, messageID);
                }
            }
        });
    }

    public void setRoomStateChangeListener(RoomStateChangeListener roomStateChangeListener) {
        this.roomStateChangeListener = roomStateChangeListener;
    }

    public void addUserChangeListener(RoomUserChangeListener listener) {
        roomUserChangeListenerList.add(listener);
    }

    public void removeUserChangeListener(RoomUserChangeListener listener) {
        roomUserChangeListenerList.remove(listener);
    }

    public void addStreamChangeListener(RoomStreamChangeListener listener) {
        roomStreamChangeListenerList.add(listener);
    }

    public void removeStreamChangeListener(RoomStreamChangeListener listener) {
        roomStreamChangeListenerList.remove(listener);
    }

    public void addCustomCommandListener(IMCustomCommandListener listener) {
        customCommandListenerList.add(listener);
    }

    public void removeCustomCommandListener(IMCustomCommandListener listener) {
        customCommandListenerList.remove(listener);
    }

    public void addBarrageMessageListener(IMBarrageMessageListener listener) {
        barrageMessageListenerList.add(listener);
    }

    public void removeBarrageMessageListener(IMBarrageMessageListener listener) {
        barrageMessageListenerList.remove(listener);
    }

    public interface RoomStateChangeListener {

        void onRoomStateChanged(String roomID, ZegoRoomStateChangedReason reason, int errorCode,
            JSONObject extendedData);
    }

    public interface RoomUserChangeListener {

        void onUserEnter(List<ZEGOLiveUser> userList);

        void onUserLeft(List<ZEGOLiveUser> userList);
    }

    public interface RoomStreamChangeListener {

        void onStreamAdd(List<ZEGOLiveUser> userList);

        void onStreamRemove(List<ZEGOLiveUser> userList);
    }

    public interface IMCustomCommandListener {

        void onIMRecvCustomCommand(String roomID, ZegoUser fromUser, String command);
    }

    public interface IMBarrageMessageListener {

        void onIMRecvBarrageMessage(String roomID, ArrayList<ZegoBarrageMessageInfo> messageList);

        void onIMSendBarrageMessageResult(int errorCode, String message, String messageID);
    }
}
