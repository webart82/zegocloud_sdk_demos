package com.zegocloud.demo.callwithinvitation;

import android.app.Application;
import android.view.TextureView;

import com.zegocloud.demo.callwithinvitation.internal.ZIMService;
import com.zegocloud.demo.callwithinvitation.internal.ZIMService.ConnectionStateChangeListener;
import com.zegocloud.demo.callwithinvitation.internal.ZIMService.InvitationListener;
import com.zegocloud.demo.callwithinvitation.internal.ExpressService;
import com.zegocloud.demo.callwithinvitation.utils.LogUtil;

import java.util.Collections;
import java.util.List;

import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zegoexpress.constants.ZegoViewMode;
import im.zego.zim.callback.ZIMCallAcceptanceSentCallback;
import im.zego.zim.callback.ZIMCallCancelSentCallback;
import im.zego.zim.callback.ZIMCallInvitationSentCallback;
import im.zego.zim.callback.ZIMCallRejectionSentCallback;
import im.zego.zim.callback.ZIMLoggedInCallback;

public class ZEGOSDKManager {

    public ExpressService expressService = new ExpressService();
    public ZIMService zimService = new ZIMService();
    private static final class Holder {

        private static final ZEGOSDKManager INSTANCE = new ZEGOSDKManager();
    }

    public static ZEGOSDKManager getInstance() {
        return Holder.INSTANCE;
    }

    public void initSDK(Application application, long appID, String appSign) {
        expressService.initSDK(application, appID, appSign);
        zimService.initSDK(application, appID, appSign);
    }

    public void connectUser(String userID, String userName, ZIMLoggedInCallback callback) {
        zimService.connectUser(userID, userName, callback);
        expressService.connectUser(userID, userName);
    }

    public void disconnectUser() {
        zimService.disconnectUser();
        expressService.disconnectUser();
    }

    public void startCameraPreview(TextureView textureView, ZegoViewMode viewMode) {
        expressService.startCameraPreview(textureView, viewMode);
    }

    public void stopCameraPreview() {
        expressService.stopCameraPreview();
    }

    public void startPublishLocalAudioVideo() {
        expressService.startPublishLocalVideo();
    }

    public void stopPublishLocalAudioVideo() {
        expressService.stopPublishLocalVideo();
    }

    public void startPlayRemoteAudioVideo(TextureView textureView, String streamID, ZegoViewMode viewMode) {
        expressService.startPlayRemoteAudioVideo(textureView, streamID, viewMode);
    }

    public void stopPlayRemoteAudioVideo(String streamID) {
        expressService.stopPlayRemoteAudioVideo(streamID);
    }

    public void joinExpressRoom(String roomID, IZegoRoomLoginCallback callback) {
        expressService.joinRoom(roomID, callback);
    }

    public void leaveExpressRoom() {
        setBusy(false);
        expressService.leaveRoom();
    }

    public void enableCamera(boolean enable) {
        expressService.enableCamera(enable);
    }

    public void openMicrophone(boolean enable) {
        expressService.openMicrophone(enable);
    }

    public void useFrontCamera(boolean useFront) {
        expressService.useFrontCamera(useFront);
    }

    public void audioRouteToSpeaker(boolean use) {
        expressService.audioRouteToSpeaker(use);
    }

    public void setExpressEventHandler(IZegoEventHandler eventHandler) {
        expressService.setEventHandler(eventHandler);
    }

    public boolean isIMUserConnected() {
        return zimService.isUserConnected();
    }

    public void inviteUser(String userID, String extendedData, ZIMCallInvitationSentCallback callback) {
        zimService.inviteUser(Collections.singletonList(userID), extendedData, callback);
    }

    public void inviteUser(List<String> userIDs, String extendedData, ZIMCallInvitationSentCallback callback) {
        zimService.inviteUser(userIDs, extendedData, callback);
    }

    public void callAccept(String callID, ZIMCallAcceptanceSentCallback callback) {
        zimService.callAccept(callID, callback);
    }

    public void callReject(String callID, ZIMCallRejectionSentCallback callback) {
        zimService.callReject(callID, callback);
    }

    public void autoRejectCallInviteCauseBusy(String callID, ZIMCallRejectionSentCallback callback) {
        zimService.autoRejectCallInviteCauseBusy(callID, callback);
    }

    public void cancelInvite(String userID, String callID, ZIMCallCancelSentCallback callback) {
        zimService.cancelInvite(Collections.singletonList(userID), callID, callback);
    }

    public void setBusy(boolean busy) {
        zimService.setBusy(busy);
    }

    public boolean isBusy() {
        return zimService.isBusy();
    }

    public void addInvitationListener(InvitationListener listener) {
        zimService.addInvitationListener(listener);
    }

    public void removeInvitationListener(InvitationListener listener) {
        zimService.removeInvitationListener(listener);
    }

    public void setDebugMode(boolean debugMode) {
        LogUtil.setDebug(debugMode);
    }

    public void addIMConnectionStateChangeListener(ConnectionStateChangeListener connectionStateChangeListener) {
        zimService.addConnectionStateChangeListener(connectionStateChangeListener);
    }

    public void removeIMConnectionStateChangeListener(ConnectionStateChangeListener connectionStateChangeListener) {
        zimService.removeConnectionStateChangeListener(connectionStateChangeListener);
    }
}
