package com.zegocloud.demo.cohosting.internal;

import android.app.Application;
import com.zegocloud.demo.cohosting.internal.zim.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.zim.ZEGOInviteState;
import com.zegocloud.demo.cohosting.utils.LogUtil;
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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.json.JSONObject;

public class ZEGOIMService {

    private ZIM zim;
    private ZIMUserInfo currentZimUserInfo;
    private ZIMConnectionState connectionState;
    private List<ConnectionStateChangeListener> connectionStateChangeListeners = new ArrayList<>();
    private boolean busy;

    private Map<String, ZEGOInvitation> zegoInvitationMap = new HashMap<>();
    private List<OutgoingInvitationListener> outgoingInvitationListenerList = new ArrayList<>();
    private List<IncomingInvitationListener> incomingInvitationListenerList = new ArrayList<>();

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
                    ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                    if (zegoInvitation != null) {
                        zegoInvitation.setState(ZEGOInviteState.SEND_TIME_OUT);
                    }

                    for (OutgoingInvitationListener outgoingInvitationListener : outgoingInvitationListenerList) {
                        outgoingInvitationListener.onSendInvitationButReceiveResponseTimeout(callID, invitees);
                    }

                    if (zegoInvitation != null) {
                        zegoInvitationMap.remove(zegoInvitation.callID);
                    }
                }

                @Override
                public void onCallInvitationTimeout(ZIM zim, String callID) {
                    super.onCallInvitationTimeout(zim, callID);
                    ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                    if (zegoInvitation != null) {
                        zegoInvitation.setState(ZEGOInviteState.RECV_TIME_OUT);
                    }

                    for (IncomingInvitationListener inComingInvitationListener : incomingInvitationListenerList) {
                        inComingInvitationListener.onReceiveInvitationButResponseTimeout(callID);
                    }

                    if (zegoInvitation != null) {
                        zegoInvitationMap.remove(zegoInvitation.callID);
                    }
                }

                @Override
                public void onCallInvitationReceived(ZIM zim, ZIMCallInvitationReceivedInfo info, String callID) {
                    super.onCallInvitationReceived(zim, info, callID);
                    LogUtil.d(
                        "onCallInvitationReceived() called with: zim = [" + zim + "], info = [" + info + "], callID = ["
                            + callID + "]");
                    ZEGOInvitation ZEGOInvitation = new ZEGOInvitation();
                    ZEGOInvitation.inviter = info.inviter;
                    ZEGOInvitation.callID = callID;
                    ZEGOInvitation.inviteExtendedData = info.extendedData;
                    ZEGOInvitation.invitees = new ArrayList<>();
                    ZEGOInvitation.invitees.add(currentZimUserInfo.userID);
                    ZEGOInvitation.setState(ZEGOInviteState.RECV_NEW);
                    zegoInvitationMap.put(ZEGOInvitation.callID, ZEGOInvitation);
                    for (IncomingInvitationListener invitationListener : incomingInvitationListenerList) {
                        invitationListener.onReceiveNewInvitation(callID, info.inviter, info.extendedData);
                    }
                }

                @Override
                public void onCallInvitationRejected(ZIM zim, ZIMCallInvitationRejectedInfo info, String callID) {
                    super.onCallInvitationRejected(zim, info, callID);
                    ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                    if (zegoInvitation != null) {
                        zegoInvitation.setState(ZEGOInviteState.SEND_IS_REJECTED);
                    }

                    for (OutgoingInvitationListener outgoingInvitationListener : outgoingInvitationListenerList) {
                        outgoingInvitationListener.onSendInvitationButIsRejected(callID, info.invitee,
                            info.extendedData);
                    }

                    if (zegoInvitation != null) {
                        zegoInvitationMap.remove(zegoInvitation.callID);
                    }
                }

                @Override
                public void onCallInvitationCancelled(ZIM zim, ZIMCallInvitationCancelledInfo info, String callID) {
                    super.onCallInvitationCancelled(zim, info, callID);
                    ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                    if (zegoInvitation != null) {
                        zegoInvitation.setState(ZEGOInviteState.RECV_IS_CANCELLED);
                    }

                    for (IncomingInvitationListener invitationListener : incomingInvitationListenerList) {
                        invitationListener.onReceiveInvitationButIsCancelled(callID, info.inviter, info.extendedData);
                    }

                    if (zegoInvitation != null) {
                        zegoInvitationMap.remove(zegoInvitation.callID);
                    }
                }

                @Override
                public void onCallInvitationAccepted(ZIM zim, ZIMCallInvitationAcceptedInfo info, String callID) {
                    super.onCallInvitationAccepted(zim, info, callID);
                    ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                    if (zegoInvitation != null) {
                        zegoInvitation.setState(ZEGOInviteState.SEND_IS_ACCEPTED);
                    }

                    for (OutgoingInvitationListener outgoingInvitationListener : outgoingInvitationListenerList) {
                        outgoingInvitationListener.onSendInvitationAndIsAccepted(callID, info.invitee,
                            info.extendedData);
                    }

                    if (zegoInvitation != null) {
                        zegoInvitationMap.remove(zegoInvitation.callID);
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
                LogUtil.d("onLoggedIn() called with: errorInfo = [" + errorInfo.getCode() + "]");
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
        currentZimUserInfo = null;
        connectionStateChangeListeners.clear();
        connectionState = ZIMConnectionState.DISCONNECTED;

        zegoInvitationMap.clear();
        outgoingInvitationListenerList.clear();
        incomingInvitationListenerList.clear();

        if (zim == null) {
            return;
        }
        zim.logout();
    }

    public boolean isUserConnected() {
        return connectionState == ZIMConnectionState.CONNECTED;
    }

    public void inviteUser(List<String> userIDs, String extendedData, ZIMCallInvitationSentCallback listener) {
        LogUtil.d(
            "inviteUser() called with: userIDs = [" + userIDs + "], extendedData = [" + extendedData + "], callback = ["
                + listener + "]");
        if (zim == null && listener != null) {
            ZIMError errorInfo = new ZIMError();
            errorInfo.setCode(ZIMErrorCode.NO_INIT);
            listener.onCallInvitationSent(null, null, errorInfo);
            return;
        }
        ZIMCallInviteConfig config = new ZIMCallInviteConfig();
        config.extendedData = extendedData;

        ZEGOInvitation zegoInvitation = new ZEGOInvitation();
        zegoInvitation.invitees = userIDs;
        zegoInvitation.inviteExtendedData = extendedData;
        zim.callInvite(userIDs, config, new ZIMCallInvitationSentCallback() {
            @Override
            public void onCallInvitationSent(String callID, ZIMCallInvitationSentInfo info, ZIMError errorInfo) {
                LogUtil.d("onCallInvitationSent() called with: callID = [" + callID + "], info = [" + info
                    + "], errorInfo = [" + errorInfo.getCode() + "]");
                zegoInvitation.inviter = currentZimUserInfo.userID;
                if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                    zegoInvitation.callID = callID;
                    zegoInvitation.setState(ZEGOInviteState.SEND_NEW);
                    zegoInvitationMap.put(zegoInvitation.callID, zegoInvitation);
                }
                if (listener != null) {
                    listener.onCallInvitationSent(callID, info, errorInfo);
                }
                for (OutgoingInvitationListener outgoingInvitationListener : outgoingInvitationListenerList) {
                    outgoingInvitationListener.onActionSendInvitation(callID, info, errorInfo);
                }
            }
        });
    }

    public void acceptInvite(String callID, ZIMCallAcceptanceSentCallback callback) {
        LogUtil.d("acceptInvite() called with: callID = [" + callID + "], callback = [" + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallAcceptConfig config = new ZIMCallAcceptConfig();
        zim.callAccept(callID, config, new ZIMCallAcceptanceSentCallback() {
            @Override
            public void onCallAcceptanceSent(String callID, ZIMError errorInfo) {
                LogUtil.d(
                    "onCallAcceptanceSent() called with: callID = [" + callID + "], errorInfo = [" + errorInfo + "]");
                ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInviteState.RECV_ACCEPT);
                }

                if (callback != null) {
                    callback.onCallAcceptanceSent(callID, errorInfo);
                }
                for (IncomingInvitationListener incomingInvitationListener : incomingInvitationListenerList) {
                    incomingInvitationListener.onActionAcceptInvitation(callID, errorInfo);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.callID);
                }
            }
        });
    }

    public void autoRejectInvite(String callID, ZIMCallRejectionSentCallback callback) {
        LogUtil.d("autoRejectInvite() called with: callID = [" + callID + "], callback = [" + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallRejectConfig config = new ZIMCallRejectConfig();

        zim.callReject(callID, config, new ZIMCallRejectionSentCallback() {
            @Override
            public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                LogUtil.d(
                    "onCallRejectionSent() called with: callID = [" + callID + "], errorInfo = [" + errorInfo + "]");
                if (callback != null) {
                    callback.onCallRejectionSent(callID, errorInfo);
                }
            }
        });
    }

    public void rejectInvite(String callID, ZIMCallRejectionSentCallback callback) {
        LogUtil.d("rejectInvite() called with: callID = [" + callID + "], callback = [" + callback + "]");
        if (zim == null) {
            return;
        }
        ZIMCallRejectConfig config = new ZIMCallRejectConfig();

        zim.callReject(callID, config, new ZIMCallRejectionSentCallback() {
            @Override
            public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                LogUtil.d(
                    "onCallRejectionSent() called with: callID = [" + callID + "], errorInfo = [" + errorInfo + "]");
                ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInviteState.RECV_REJECT);
                }

                if (callback != null) {
                    callback.onCallRejectionSent(callID, errorInfo);
                }

                for (IncomingInvitationListener incomingInvitationListener : incomingInvitationListenerList) {
                    incomingInvitationListener.onActionRejectInvitation(callID, errorInfo);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.callID);
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
                    + "], errorInfo = [" + errorInfo + "]");
                ZEGOInvitation zegoInvitation = zegoInvitationMap.get(callID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInviteState.SEND_CANCEL);
                }

                if (callback != null) {
                    callback.onCallCancelSent(callID, errorInvitees, errorInfo);
                }
                for (OutgoingInvitationListener outgoingInvitationListener : outgoingInvitationListenerList) {
                    outgoingInvitationListener.onActionCancelInvitation(callID, errorInvitees, errorInfo);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.callID);
                }
            }
        });
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

    public ZEGOInvitation getZEGOInvitation(String callID) {
        return zegoInvitationMap.get(callID);
    }

    public void addOutgoingInvitationListener(OutgoingInvitationListener listener) {
        outgoingInvitationListenerList.add(listener);
    }

    public void removeOutgoingInvitationListener(OutgoingInvitationListener listener) {
        outgoingInvitationListenerList.remove(listener);
    }

    public void addIncomingInvitationListener(IncomingInvitationListener listener) {
        incomingInvitationListenerList.add(listener);
    }

    public void removeIncomingInvitationListener(IncomingInvitationListener listener) {
        incomingInvitationListenerList.remove(listener);
    }

    public interface OutgoingInvitationListener {

        void onActionSendInvitation(String callID, ZIMCallInvitationSentInfo info, ZIMError errorInfo);

        void onActionCancelInvitation(String callID, ArrayList<String> errorInvitees, ZIMError errorInfo);

        void onSendInvitationButReceiveResponseTimeout(String callID, ArrayList<String> invitees);

        void onSendInvitationAndIsAccepted(String callID, String invitee, String extendedData);

        void onSendInvitationButIsRejected(String callID, String invitee, String extendedData);

    }

    public interface IncomingInvitationListener {

        void onReceiveNewInvitation(String callID, String userID, String extendedData);

        void onReceiveInvitationButResponseTimeout(String callID);

        void onReceiveInvitationButIsCancelled(String callID, String inviter, String extendedData);

        void onActionAcceptInvitation(String callID, ZIMError errorInfo);

        void onActionRejectInvitation(String callID, ZIMError errorInfo);
    }
}
