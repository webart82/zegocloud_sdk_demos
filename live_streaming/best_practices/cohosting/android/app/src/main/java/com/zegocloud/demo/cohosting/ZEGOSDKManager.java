package com.zegocloud.demo.cohosting;

import android.app.Application;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.ZEGOIMService;
import com.zegocloud.demo.cohosting.utils.LogUtil;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zim.callback.ZIMLoggedInCallback;

public class ZEGOSDKManager {

    public ZEGOExpressService rtcService = new ZEGOExpressService();
    public ZEGOIMService imService = new ZEGOIMService();

    private static final class Holder {

        private static final ZEGOSDKManager INSTANCE = new ZEGOSDKManager();
    }

    public static ZEGOSDKManager getInstance() {
        return Holder.INSTANCE;
    }

    public void initSDK(Application application, long appID, String appSign) {
        rtcService.initSDK(application, appID, appSign);
        imService.initSDK(application, appID, appSign);
    }

    public void connectUser(String userID, String userName, ZIMLoggedInCallback callback) {
        imService.connectUser(userID, userName, callback);
        rtcService.connectUser(userID, userName);
    }

    public void disconnectUser() {
        imService.disconnectUser();
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
        imService.setBusy(busy);
    }

    public boolean isBusy() {
        return imService.isBusy();
    }


    public void setDebugMode(boolean debugMode) {
        LogUtil.setDebug(debugMode);
    }
}
