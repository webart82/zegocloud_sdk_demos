package com.zegocloud.demo.cohosting.internal.invitation;

import android.app.Application;
import android.util.Log;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.invitation.common.AcceptInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.CancelInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ConnectCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.IncomingInvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.InvitationInterface;
import com.zegocloud.demo.cohosting.internal.invitation.common.InvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.OutgoingInvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.RejectInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.SendInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitationState;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInviteeState;
import com.zegocloud.demo.cohosting.internal.invitation.impl.ExpressInvitationImpl;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Objects;

public class ZEGOInvitationService {

    private Map<String, ZEGOInvitation> zegoInvitationMap = new HashMap<>();
    private List<OutgoingInvitationListener> outgoingInvitationListenerList = new ArrayList<>();
    private List<IncomingInvitationListener> incomingInvitationListenerList = new ArrayList<>();

    private boolean busy;
    private InvitationInterface invitationInterface;

    private String mUserID;
    private String mUserName;
    private static final String TAG = "ZEGOInvitationService";

    public ZEGOInvitation getZEGOInvitation(String invitationID) {
        ZEGOInvitation invitation = zegoInvitationMap.get(invitationID);
        if (invitation == null) {
            for (String key : zegoInvitationMap.keySet()) {
                if (key.contains(invitationID)) {
                    return zegoInvitationMap.get(key);
                }
            }
        }
        return invitation;
    }

    public void setBusy(boolean busy) {
        this.busy = busy;
    }

    public boolean isBusy() {
        return busy;
    }

    public ZEGOInvitationService() {
        invitationInterface = new ExpressInvitationImpl();
        invitationInterface.setInvitationListener(new InvitationListener() {
            @Override
            public void onInComingNewInvitation(String invitationID, String inviterID, String extendedData) {
                Log.d(TAG, "onInComingNewInvitation() called with: invitationID = [" + invitationID + "], inviterID = ["
                    + inviterID + "], extendedData = [" + extendedData + "]");
                ZEGOInvitation ZEGOInvitation = new ZEGOInvitation();
                ZEGOInvitation.inviter = inviterID;
                ZEGOInvitation.invitationID = invitationID;
                ZEGOInvitation.extendedData = extendedData;
                ZEGOInvitation.invitees = new ArrayList<>();
                ZEGOInvitation.invitees.add(mUserID);
                ZEGOInvitation.inviteeStateMap = new HashMap<>();
                ZEGOInvitation.inviteeStateMap.put(mUserID, ZEGOInviteeState.RECV);
                ZEGOInvitation.setState(ZEGOInvitationState.RECV_NEW);
                zegoInvitationMap.put(ZEGOInvitation.invitationID, ZEGOInvitation);

                for (IncomingInvitationListener listener : incomingInvitationListenerList) {
                    listener.onReceiveNewInvitation(invitationID, inviterID, extendedData);
                }
            }

            @Override
            public void onInComingInvitationButResponseTimeout(String invitationID) {
                Log.d(TAG,
                    "onInComingInvitationButResponseTimeout() called with: invitationID = [" + invitationID + "]");
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.RECV_TIME_OUT);
                    zegoInvitation.inviteeStateMap.put(mUserID, ZEGOInviteeState.TIME_OUT);
                }

                for (IncomingInvitationListener listener : incomingInvitationListenerList) {
                    listener.onReceiveInvitationButResponseTimeout(invitationID);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }

            }

            @Override
            public void onInComingInvitationButIsCancelled(String invitationID, String inviter, String extendedData) {
                Log.d(TAG, "onInComingInvitationButIsCancelled() called with: invitationID = [" + invitationID
                    + "], inviter = [" + inviter + "], extendedData = [" + extendedData + "]");
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.RECV_IS_CANCELLED);
                }

                for (IncomingInvitationListener listener : incomingInvitationListenerList) {
                    listener.onReceiveInvitationButIsCancelled(invitationID, inviter, extendedData);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }
            }

            @Override
            public void onOutgoingInvitationButReceiveResponseTimeout(String invitationID, List<String> invitees) {
                Log.d(TAG,
                    "onOutgoingInvitationButReceiveResponseTimeout() called with: invitationID = [" + invitationID
                        + "], invitees = [" + invitees + "]");
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.SEND_TIME_OUT);
                    for (String invitee : invitees) {
                        zegoInvitation.inviteeStateMap.put(invitee, ZEGOInviteeState.TIME_OUT);
                    }
                }

                for (OutgoingInvitationListener listener : outgoingInvitationListenerList) {
                    listener.onSendInvitationButReceiveResponseTimeout(invitationID, invitees);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }
            }

            @Override
            public void onOutgoingInvitationAndIsAccepted(String invitationID, String invitee, String extendedData) {
                Log.d(TAG, "onOutgoingInvitationAndIsAccepted() called with: invitationID = [" + invitationID
                    + "], invitee = [" + invitee + "], extendedData = [" + extendedData + "]");
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.SEND_IS_ACCEPTED);
                    zegoInvitation.inviteeStateMap.put(invitee, ZEGOInviteeState.ACCEPT);
                }

                for (OutgoingInvitationListener listener : outgoingInvitationListenerList) {
                    listener.onSendInvitationAndIsAccepted(invitationID, invitee, extendedData);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }
            }

            @Override
            public void onOutgoingInvitationButIsRejected(String invitationID, String invitee, String extendedData) {
                Log.d(TAG, "onOutgoingInvitationButIsRejected() called with: invitationID = [" + invitationID
                    + "], invitee = [" + invitee + "], extendedData = [" + extendedData + "]");
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.SEND_IS_REJECTED);
                    zegoInvitation.inviteeStateMap.put(invitee, ZEGOInviteeState.REJECT);
                }

                for (OutgoingInvitationListener listener : outgoingInvitationListenerList) {
                    listener.onSendInvitationButIsRejected(invitationID, invitee, extendedData);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }
            }
        });
    }

    public void initSDK(Application application, long appID, String appSign) {
        invitationInterface.initSDK(application, appID, appSign);
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

    public void connectUser(String userID, String userName, ConnectCallback callback) {

        invitationInterface.connectUser(userID, userName, new ConnectCallback() {
            @Override
            public void onResult(int errorCode, String message) {
                if (errorCode == 0) {
                    mUserID = userID;
                    mUserName = userName;
                    if (callback != null) {
                        callback.onResult(errorCode, message);
                    }
                }
            }
        });
    }

    public void disconnectUser() {
        this.mUserID = null;
        this.mUserName = null;
        clearInvitations();
        clearListeners();
        invitationInterface.disconnectUser();
    }

    public void inviteUser(String userID, String extendedData, SendInvitationCallback callback) {
        Log.d(TAG,
            "inviteUser() called with: userID = [" + userID + "], extendedData = [" + extendedData + "], callback = ["
                + callback + "]");
        ZEGOInvitation zegoInvitation = new ZEGOInvitation();
        zegoInvitation.invitees = Collections.singletonList(userID);
        zegoInvitation.extendedData = extendedData;
        zegoInvitation.inviter = mUserID;
        zegoInvitation.inviteeStateMap = new HashMap<>();

        invitationInterface.inviteUser(userID, extendedData, new SendInvitationCallback() {

            @Override
            public void onResult(int errorCode, String invitationID, List<String> errorInvitees) {
                if (errorCode == 0) {
                    zegoInvitation.invitationID = invitationID;
                    zegoInvitation.setState(ZEGOInvitationState.SEND_NEW);
                    for (String invitee : errorInvitees) {
                        zegoInvitation.inviteeStateMap.put(invitee, ZEGOInviteeState.UNKNOWN);
                    }
                    List<String> successUserList = new ArrayList<>(zegoInvitation.invitees);
                    successUserList.removeAll(errorInvitees);
                    for (String invitee : successUserList) {
                        zegoInvitation.inviteeStateMap.put(invitee, ZEGOInviteeState.RECV);
                    }
                    zegoInvitationMap.put(zegoInvitation.invitationID, zegoInvitation);
                }
                if (callback != null) {
                    callback.onResult(errorCode, invitationID, errorInvitees);
                }
                for (OutgoingInvitationListener outgoingInvitationListener : outgoingInvitationListenerList) {
                    outgoingInvitationListener.onActionSendInvitation(errorCode, invitationID, extendedData,
                        errorInvitees);
                }
            }
        });
    }


    public void acceptInvite(ZEGOInvitation invitation, AcceptInvitationCallback callback) {
        Log.d(TAG, "acceptInvite() called with: invitation = [" + invitation + "], callback = [" + callback + "]");
        invitationInterface.acceptInvite(invitation, new AcceptInvitationCallback() {
            @Override
            public void onResult(int errorCode, String invitationID) {
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.RECV_ACCEPT);
                    zegoInvitation.inviteeStateMap.put(mUserID, ZEGOInviteeState.ACCEPT);
                }

                if (callback != null) {
                    callback.onResult(errorCode, invitationID);
                }
                for (IncomingInvitationListener incomingInvitationListener : incomingInvitationListenerList) {
                    incomingInvitationListener.onActionAcceptInvitation(errorCode, invitationID);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }
            }
        });
    }


    public void rejectInvite(ZEGOInvitation invitation, RejectInvitationCallback callback) {
        Log.d(TAG, "rejectInvite() called with: invitation = [" + invitation + "], callback = [" + callback + "]");
        invitationInterface.rejectInvite(invitation, new RejectInvitationCallback() {
            @Override
            public void onResult(int errorCode, String invitationID) {
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.RECV_REJECT);
                    zegoInvitation.inviteeStateMap.put(mUserID, ZEGOInviteeState.REJECT);
                }

                if (callback != null) {
                    callback.onResult(errorCode, invitationID);
                }

                for (IncomingInvitationListener incomingInvitationListener : incomingInvitationListenerList) {
                    incomingInvitationListener.onActionRejectInvitation(errorCode, invitationID);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }
            }
        });
    }


    public void cancelInvite(ZEGOInvitation invitation, CancelInvitationCallback callback) {
        Log.d(TAG, "cancelInvite() called with: invitation = [" + invitation + "], callback = [" + callback + "]");
        invitationInterface.cancelInvite(invitation, new CancelInvitationCallback() {

            @Override
            public void onResult(int errorCode, String invitationID, List<String> errorInvitees) {
                ZEGOInvitation zegoInvitation = getZEGOInvitation(invitationID);
                if (zegoInvitation != null) {
                    zegoInvitation.setState(ZEGOInvitationState.SEND_CANCEL);
                }

                if (callback != null) {
                    callback.onResult(errorCode, invitationID, errorInvitees);
                }
                for (OutgoingInvitationListener outgoingInvitationListener : outgoingInvitationListenerList) {
                    outgoingInvitationListener.onActionCancelInvitation(errorCode, invitationID, errorInvitees);
                }

                if (zegoInvitation != null) {
                    zegoInvitationMap.remove(zegoInvitation.invitationID);
                }
            }
        });
    }

    public void clearInvitations() {
        zegoInvitationMap.clear();
        busy = false;
    }

    public void clearListeners() {
        outgoingInvitationListenerList.clear();
        incomingInvitationListenerList.clear();
    }

    public boolean isOtherUserInviteExisted(String inviterID) {
        for (ZEGOInvitation invitation : zegoInvitationMap.values()) {
            if (!invitation.isFinished()) {
                if (Objects.equals(invitation.inviter, inviterID)) {
                    return true;
                }
            }
        }
        return false;
    }

    public ZEGOInvitation getUserInvitation(String inviterID) {
        for (ZEGOInvitation invitation : zegoInvitationMap.values()) {
            if (!invitation.isFinished()) {
                if (Objects.equals(invitation.inviter, inviterID)) {
                    return invitation;
                }
            }
        }
        return null;
    }

    public List<ZEGOLiveUser> getOtherUserInviteList() {
        List<ZEGOLiveUser> userList = new ArrayList<>();
        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        ZEGOLiveUser localUser = rtcService.getLocalUser();
        for (Entry<String, ZEGOInvitation> entry : zegoInvitationMap.entrySet()) {
            ZEGOInvitation invitation = entry.getValue();
            if (!invitation.isFinished()) {
                String inviter = invitation.inviter;
                if (!Objects.equals(localUser.userID, inviter)) {
                    userList.add(rtcService.getUser(inviter));
                }
            }
        }
        return userList;
    }
}
