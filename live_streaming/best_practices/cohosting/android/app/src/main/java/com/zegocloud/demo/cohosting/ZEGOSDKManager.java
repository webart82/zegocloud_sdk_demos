package com.zegocloud.demo.cohosting;

import android.app.Application;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.invitation.common.ConnectCallback;
import com.zegocloud.demo.cohosting.internal.invitation.ZEGOInvitationService;
import com.zegocloud.demo.cohosting.utils.LogUtil;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;

public class ZEGOSDKManager {

    public ZEGOExpressService rtcService = new ZEGOExpressService();
    public ZEGOInvitationService invitationService = new ZEGOInvitationService();

    private static final class Holder {

        private static final ZEGOSDKManager INSTANCE = new ZEGOSDKManager();
    }

    public static ZEGOSDKManager getInstance() {
        return Holder.INSTANCE;
    }

    public void initSDK(Application application, long appID, String appSign) {
        rtcService.initSDK(application, appID, appSign);
        invitationService.initSDK(application, appID, appSign);
    }

    public void connectUser(String userID, String userName, ConnectCallback callback) {
        invitationService.connectUser(userID, userName, callback);
        rtcService.connectUser(userID, userName);
    }

    public void disconnectUser() {
        invitationService.disconnectUser();
        rtcService.disConnectUser();
    }

    public void joinRTCRoom(String roomID, IZegoRoomLoginCallback callback) {
        rtcService.joinRoom(roomID, callback);
    }

    public void leaveRTCRoom() {
        setBusy(false);
        rtcService.leaveRoom();
    }

    public void setBusy(boolean busy) {
        invitationService.setBusy(busy);
    }

    public boolean isBusy() {
        return invitationService.isBusy();
    }


    public void setDebugMode(boolean debugMode) {
        LogUtil.setDebug(debugMode);
    }
}
