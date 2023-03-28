package com.zegocloud.demo.callwithinvitation.call;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

import com.zegocloud.demo.callwithinvitation.ZEGOSDKManager;
import com.zegocloud.demo.callwithinvitation.internal.ZIMService.InvitationListener;
import com.zegocloud.demo.callwithinvitation.utils.ToastUtil;
import com.zegocloud.demo.callwithinvitation.call.internal.CallInviteExtendedData;
import com.zegocloud.demo.callwithinvitation.call.internal.CallInviteInfo;

import java.util.ArrayList;

import im.zego.zim.callback.ZIMCallRejectionSentCallback;
import im.zego.zim.entity.ZIMCallInvitationSentInfo;
import im.zego.zim.entity.ZIMError;


/*
usage:
    <service
      android:name=".call.CallBackgroundService"
      android:enabled="true"
      android:exported="false" />
*/
public class CallBackgroundService extends Service {

    private InvitationListener listener = new InvitationListener() {
        @Override
        public void onIncomingCallInvitationReceived(String callID, String userID, String extendedData) {
            if (ZEGOSDKManager.getInstance().isBusy()) {
                ZEGOSDKManager.getInstance().autoRejectCallInviteCauseBusy(callID, new ZIMCallRejectionSentCallback() {
                    @Override
                    public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                        ToastUtil.show(getApplicationContext(), "busy auto reject");
                    }
                });
                return;
            }
            ZEGOSDKManager.getInstance().setBusy(true);

            CallInviteExtendedData callInviteExtendedData = CallInviteExtendedData.parseExtendedData(extendedData);
            CallInviteInfo callInviteInfo = new CallInviteInfo();
            callInviteInfo.callID = callID;
            callInviteInfo.callerUserID = userID;
            callInviteInfo.callerUserName = callInviteExtendedData.callerUserName;
            callInviteInfo.calleeUserID = ZEGOSDKManager.getInstance().expressService.getUserInfo().userID;
            callInviteInfo.callType = callInviteExtendedData.type;
            callInviteInfo.isOutgoingCall = false;

            Intent intent = new Intent(getApplicationContext(), IncomingCallDialog.class);
            intent.putExtra("callInviteInfo", callInviteInfo);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);

        }

        @Override
        public void onIncomingCallInvitationTimeout(String inviter) {
            ZEGOSDKManager.getInstance().setBusy(false);
        }

        @Override
        public void onOutgoingCallInvitationTimeout(String callID, ArrayList<String> invitees) {
            ZEGOSDKManager.getInstance().setBusy(false);
        }

        @Override
        public void onOutgoingCallInvitationAccepted(String callID, String invitee, String extendedData) {
        }

        @Override
        public void onOutgoingCallInvitationRejected(String callID, String invitee, String extendedData) {
            ZEGOSDKManager.getInstance().setBusy(false);
        }

        @Override
        public void onIncomingCallInvitationCancelled(String callID, String inviter, String extendedData) {
            ZEGOSDKManager.getInstance().setBusy(false);
        }

        @Override
        public void onIncomingCallInvitationAccepted(String callID, ZIMError errorInfo) {
            InvitationListener.super.onIncomingCallInvitationAccepted(callID, errorInfo);
            ZEGOSDKManager.getInstance().setBusy(true);
        }

        @Override
        public void onIncomingCallInvitationRejected(String callID, ZIMError errorInfo) {
            InvitationListener.super.onIncomingCallInvitationRejected(callID, errorInfo);
            ZEGOSDKManager.getInstance().setBusy(false);
        }

        @Override
        public void onOutgoingCallInvitationCancelled(String callID, ArrayList<String> errorInvitees, ZIMError errorInfo) {
            InvitationListener.super.onOutgoingCallInvitationCancelled(callID, errorInvitees, errorInfo);
            ZEGOSDKManager.getInstance().setBusy(false);
        }

        @Override
        public void onOutgoingCallInvitationSent(String callID, ZIMCallInvitationSentInfo info, ZIMError errorInfo) {
            InvitationListener.super.onOutgoingCallInvitationSent(callID, info, errorInfo);
            ZEGOSDKManager.getInstance().setBusy(true);
        }
    };

    public CallBackgroundService() {

    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        ZEGOSDKManager.getInstance().addInvitationListener(listener);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ZEGOSDKManager.getInstance().removeInvitationListener(listener);
    }
}