package com.zegocloud.demo.callwithinvitation.internal;

import android.app.Application;

import com.zegocloud.demo.callwithinvitation.utils.LogUtil;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import im.zego.zim.ZIM;
import im.zego.zim.callback.ZIMCallAcceptanceSentCallback;
import im.zego.zim.callback.ZIMCallCancelSentCallback;
import im.zego.zim.callback.ZIMCallInvitationSentCallback;
import im.zego.zim.callback.ZIMCallRejectionSentCallback;
import im.zego.zim.callback.ZIMEventHandler;
import im.zego.zim.callback.ZIMLoggedInCallback;
import im.zego.zim.entity.ZIMAppConfig;
import im.zego.zim.entity.ZIMCallAcceptConfig;
import im.zego.zim.entity.ZIMCallCancelConfig;
import im.zego.zim.entity.ZIMCallInvitationAcceptedInfo;
import im.zego.zim.entity.ZIMCallInvitationCancelledInfo;
import im.zego.zim.entity.ZIMCallInvitationReceivedInfo;
import im.zego.zim.entity.ZIMCallInvitationRejectedInfo;
import im.zego.zim.entity.ZIMCallInvitationSentInfo;
import im.zego.zim.entity.ZIMCallInviteConfig;
import im.zego.zim.entity.ZIMCallRejectConfig;
import im.zego.zim.entity.ZIMError;
import im.zego.zim.entity.ZIMUserInfo;
import im.zego.zim.enums.ZIMConnectionEvent;
import im.zego.zim.enums.ZIMConnectionState;
import im.zego.zim.enums.ZIMErrorCode;

public class ZIMService {

    private ZIM zim;
    private ZIMUserInfo currentZimUserInfo;
    private ZIMConnectionState connectionState;
    private List<InvitationListener> invitationListeners = new ArrayList<>();
    private List<ConnectionStateChangeListener> connectionStateChangeListeners = new ArrayList<>();
    private boolean busy;

    public void initSDK(Application application, long appID, String appSign) {
        if (zim != null) {
            return;
        }
        ZIMAppConfig zimAppConfig = new ZIMAppConfig();
        zimAppConfig.appID = appID;
        zimAppConfig.appSign = appSign;
        zim = ZIM.create(zimAppConfig, application);
        if (zim != null) {
            zim.setEventHandler(new ZIMEventHandler() {
                @Override
                public void onConnectionStateChanged(ZIM zim, ZIMConnectionState state, ZIMConnectionEvent event,
                    JSONObject extendedData) {
                    super.onConnectionStateChanged(zim, state, event, extendedData);
                    LogUtil.d("onConnectionStateChanged() called with: zim = [" + zim + "], state = [" + state
                        + "], event = [" + event + "], extendedData = [" + extendedData + "]");
                    connectionState = state;
                    if (state == ZIMConnectionState.DISCONNECTED) {

                    }
                    for (ConnectionStateChangeListener connectionStateChangeListener : connectionStateChangeListeners) {
                        connectionStateChangeListener.onConnectionStateChanged(zim, state, event, extendedData);
                    }
                }

                @Override
                public void onCallInviteesAnsweredTimeout(ZIM zim, ArrayList<String> invitees, String callID) {
                    super.onCallInviteesAnsweredTimeout(zim, invitees, callID);
                    for (InvitationListener invitationListener : invitationListeners) {
                        invitationListener.onOutgoingCallInvitationTimeout(callID, invitees);
                    }
                }

                @Override
                public void onCallInvitationTimeout(ZIM zim, String callID) {
                    super.onCallInvitationTimeout(zim, callID);
                    for (InvitationListener invitationListener : invitationListeners) {
                        invitationListener.onIncomingCallInvitationTimeout(callID);
                    }
                }

                @Override
                public void onCallInvitationReceived(ZIM zim, ZIMCallInvitationReceivedInfo info, String callID) {
                    super.onCallInvitationReceived(zim, info, callID);
                    for (InvitationListener invitationListener : invitationListeners) {
                        invitationListener.onIncomingCallInvitationReceived(callID, info.inviter, info.extendedData);
                    }
                }

                @Override
                public void onCallInvitationRejected(ZIM zim, ZIMCallInvitationRejectedInfo info, String callID) {
                    super.onCallInvitationRejected(zim, info, callID);
                    for (InvitationListener invitationListener : invitationListeners) {
                        invitationListener.onOutgoingCallInvitationRejected(callID, info.invitee, info.extendedData);
                    }
                }

                @Override
                public void onCallInvitationCancelled(ZIM zim, ZIMCallInvitationCancelledInfo info, String callID) {
                    super.onCallInvitationCancelled(zim, info, callID);
                    for (InvitationListener invitationListener : invitationListeners) {
                        invitationListener.onIncomingCallInvitationCancelled(callID, info.inviter, info.extendedData);
                    }
                }

                @Override
                public void onCallInvitationAccepted(ZIM zim, ZIMCallInvitationAcceptedInfo info, String callID) {
                    super.onCallInvitationAccepted(zim, info, callID);
                    for (InvitationListener invitationListener : invitationListeners) {
                        invitationListener.onOutgoingCallInvitationAccepted(callID, info.invitee, info.extendedData);
                    }
                }
            });
        }
    }

    public void connectUser(String userID, String userName, ZIMLoggedInCallback callback) {
        if (zim == null) {
            return;
        }
        ZIMUserInfo zimUserInfo = new ZIMUserInfo();
        zimUserInfo.userID = userID;
        zimUserInfo.userName = userName;
        zim.login(zimUserInfo, new ZIMLoggedInCallback() {
            @Override
            public void onLoggedIn(ZIMError errorInfo) {
                LogUtil.d("onLoggedIn() called with: errorInfo = [" + errorInfo.code + "(+" + errorInfo.message + "]");
                if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                    currentZimUserInfo = zimUserInfo;
                }
                if (callback != null) {
                    callback.onLoggedIn(errorInfo);
                }
            }
        });
    }

    public void disconnectUser() {
        if (zim == null) {
            return;
        }
        zim.logout();
        currentZimUserInfo = null;
        connectionStateChangeListeners.clear();
        invitationListeners.clear();
        connectionState = ZIMConnectionState.DISCONNECTED;
    }

    public boolean isUserConnected() {
        return connectionState == ZIMConnectionState.CONNECTED;
    }

    public void inviteUser(String userID, String extendedData, ZIMCallInvitationSentCallback callback) {
        if (zim == null) {
            return;
        }
        inviteUser(Collections.singletonList(userID), extendedData, callback);
    }

    public void inviteUser(List<String> userIDs, String extendedData, ZIMCallInvitationSentCallback callback) {
        LogUtil.d(
            "inviteUser() called with: userIDs = [" + userIDs + "], extendedData = [" + extendedData + "], callback = ["
                + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallInviteConfig config = new ZIMCallInviteConfig();
        config.timeout = 60;
        config.extendedData = extendedData;
        zim.callInvite(userIDs, config, new ZIMCallInvitationSentCallback() {
            @Override
            public void onCallInvitationSent(String callID, ZIMCallInvitationSentInfo info, ZIMError errorInfo) {
                LogUtil.d("onCallInvitationSent() called with: callID = [" + callID + "], info = [" + info
                    + "], errorInfo = [" + errorInfo.getCode() + "]");
                if (callback != null) {
                    callback.onCallInvitationSent(callID, info, errorInfo);
                }

                for (InvitationListener invitationListener : invitationListeners) {
                    invitationListener.onOutgoingCallInvitationSent(callID, info, errorInfo);
                }
            }
        });
    }

    public void callAccept(String callID, ZIMCallAcceptanceSentCallback callback) {
        LogUtil.d("callAccept() called with: callID = [" + callID + "], callback = [" + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallAcceptConfig config = new ZIMCallAcceptConfig();
        zim.callAccept(callID, config, new ZIMCallAcceptanceSentCallback() {
            @Override
            public void onCallAcceptanceSent(String callID, ZIMError errorInfo) {
                LogUtil.d(
                    "onCallAcceptanceSent() called with: callID = [" + callID + "], errorInfo = [" + errorInfo.code + "(+" + errorInfo.message + "]");
                if (callback != null) {
                    callback.onCallAcceptanceSent(callID, errorInfo);
                }
                for (InvitationListener invitationListener : invitationListeners) {
                    invitationListener.onIncomingCallInvitationAccepted(callID, errorInfo);
                }
            }
        });
    }

    public void autoRejectCallInviteCauseBusy(String callID, ZIMCallRejectionSentCallback callback) {
        LogUtil.d("autoRejectCallInviteCauseBusy() called with: callID = [" + callID + "], callback = [" + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallRejectConfig config = new ZIMCallRejectConfig();
        config.extendedData = "busy";
        zim.callReject(callID, config, new ZIMCallRejectionSentCallback() {
            @Override
            public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                LogUtil.d(
                    "onCallRejectionSent() called with: callID = [" + callID + "], errorInfo = [" + errorInfo.code + "(+" + errorInfo.message + "]");
                if (callback != null) {
                    callback.onCallRejectionSent(callID, errorInfo);
                }
            }
        });
    }

    public void callReject(String callID, ZIMCallRejectionSentCallback callback) {
        LogUtil.d("callReject() called with: callID = [" + callID + "], callback = [" + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallRejectConfig config = new ZIMCallRejectConfig();

        zim.callReject(callID, config, new ZIMCallRejectionSentCallback() {
            @Override
            public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                LogUtil.d(
                    "onCallRejectionSent() called with: callID = [" + callID + "], errorInfo = [" + errorInfo.code + "(+" + errorInfo.message + "]");
                if (callback != null) {
                    callback.onCallRejectionSent(callID, errorInfo);
                }

                for (InvitationListener invitationListener : invitationListeners) {
                    invitationListener.onIncomingCallInvitationRejected(callID, errorInfo);
                }
            }
        });
    }

    public void cancelInvite(List<String> userIDs, String callID, ZIMCallCancelSentCallback callback) {
        LogUtil.d("cancelInvite() called with: userIDs = [" + userIDs + "], callID = [" + callID + "], callback = ["
            + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallCancelConfig config = new ZIMCallCancelConfig();
        zim.callCancel(userIDs, callID, config, new ZIMCallCancelSentCallback() {
            @Override
            public void onCallCancelSent(String callID, ArrayList<String> errorInvitees, ZIMError errorInfo) {
                LogUtil.d("onCallCancelSent() called with: callID = [" + callID + "], errorInvitees = [" + errorInvitees
                    + "], errorInfo = [" + errorInfo.code + "(+" + errorInfo.message + "]");
                if (callback != null) {
                    callback.onCallCancelSent(callID, errorInvitees, errorInfo);
                }
                for (InvitationListener invitationListener : invitationListeners) {
                    invitationListener.onOutgoingCallInvitationCancelled(callID, errorInvitees, errorInfo);
                }
            }
        });
    }

    public void addInvitationListener(InvitationListener invitationListener) {
        invitationListeners.add(invitationListener);
    }

    public void removeInvitationListener(InvitationListener listener) {
        invitationListeners.remove(listener);
    }

    public void addConnectionStateChangeListener(ConnectionStateChangeListener connectionStateChangeListener) {
        connectionStateChangeListeners.add(connectionStateChangeListener);
    }

    public void removeConnectionStateChangeListener(ConnectionStateChangeListener connectionStateChangeListener) {
        connectionStateChangeListeners.remove(connectionStateChangeListener);
    }

    public void setBusy(boolean busy) {
        this.busy = busy;
    }

    public boolean isBusy() {
        return busy;
    }

    public interface ConnectionStateChangeListener {

        void onConnectionStateChanged(ZIM zim, ZIMConnectionState state, ZIMConnectionEvent event,
            JSONObject extendedData);
    }

    public interface InvitationListener {

        default void onIncomingCallInvitationReceived(String callID, String userID, String extendedData){}


        default void onIncomingCallInvitationTimeout(String inviter){}

        default void onIncomingCallInvitationCancelled(String callID, String inviter, String extendedData){}

        default void onIncomingCallInvitationRejected(String callID, ZIMError errorInfo) {}

        default void onOutgoingCallInvitationCancelled(String callID, ArrayList<String> errorInvitees, ZIMError errorInfo) {}

        default void onOutgoingCallInvitationSent(String callID, ZIMCallInvitationSentInfo info, ZIMError errorInfo) {}

        default void onOutgoingCallInvitationTimeout(String callID, ArrayList<String> invitees){}

        default void onOutgoingCallInvitationAccepted(String callID, String invitee, String extendedData){}

        default void onOutgoingCallInvitationRejected(String callID, String invitee, String extendedData){}

        default void onIncomingCallInvitationAccepted(String callID, ZIMError errorInfo) {}
    }
}
