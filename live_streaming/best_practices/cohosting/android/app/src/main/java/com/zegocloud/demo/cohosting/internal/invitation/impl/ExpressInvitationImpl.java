package com.zegocloud.demo.cohosting.internal.invitation.impl;

import android.app.Application;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.IMCustomCommandListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.AcceptInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.CancelInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ConnectCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.InvitationInterface;
import com.zegocloud.demo.cohosting.internal.invitation.common.InvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.RejectInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.SendInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import im.zego.zegoexpress.callback.IZegoIMSendCustomCommandCallback;
import im.zego.zegoexpress.entity.ZegoUser;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import org.json.JSONException;
import org.json.JSONObject;

public class ExpressInvitationImpl implements InvitationInterface {

    private InvitationListener invitationListener;

    @Override
    public void initSDK(Application application, long appID, String appSign) {
        ZEGOSDKManager.getInstance().rtcService.addCustomCommandListener(new IMCustomCommandListener() {
            @Override
            public void onIMRecvCustomCommand(String roomID, ZegoUser fromUser, String command) {
                if (invitationListener == null) {
                    return;
                }
                String invitationID = null;
                try {
                    JSONObject jsonObject = new JSONObject(command);
                    invitationID = jsonObject.getString("invitationID");
                } catch (JSONException e) {
                }
                CoHostProtocol protocol = CoHostProtocol.parse(command);
                if (protocol != null) {
                    if (invitationID == null) {
                        invitationID = protocol.getOperatorID() + protocol.getTargetID();
                    }
                    if (protocol.isInvite() || protocol.isRequest()) {
                        invitationListener.onInComingNewInvitation(invitationID, protocol.getOperatorID(), command);
                    } else if (protocol.isCancelInvite() || protocol.isCancelRequest()) {
                        invitationListener.onInComingInvitationButIsCancelled(invitationID, protocol.getOperatorID(),
                            command);
                    } else if (protocol.isRefuseInvite() || protocol.isRefuseRequest()) {
                        invitationListener.onOutgoingInvitationButIsRejected(invitationID, protocol.getOperatorID(),
                            command);
                    } else if (protocol.isAcceptInvite() || protocol.isAcceptRequest()) {
                        invitationListener.onOutgoingInvitationAndIsAccepted(invitationID, protocol.getOperatorID(),
                            command);
                    }
                }
            }
        });
    }

    @Override
    public void connectUser(String userID, String userName, ConnectCallback callback) {
        if (callback != null) {
            callback.onResult(0, "");
        }
    }

    @Override
    public void disconnectUser() {

    }

    @Override
    public void inviteUser(String userID, String extendedData, SendInvitationCallback invitationCallback) {
        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        ZEGOLiveUser localUser = rtcService.getLocalUser();
        ZEGOLiveUser targetUser = rtcService.getUser(userID);
        if (localUser == null || targetUser == null) {
            return;
        }
        ArrayList<ZegoUser> toUser = new ArrayList<>();
        toUser.add(new ZegoUser(targetUser.userID, targetUser.userName));
        String invitationID = localUser.userID + targetUser.userID + generateRandomString();

        JSONObject jsonObject = null;
        try {
            jsonObject = new JSONObject(extendedData);
            jsonObject.put("invitationID", invitationID);
        } catch (JSONException e) {

        }
        if (jsonObject != null) {
            extendedData = jsonObject.toString();
        }
        rtcService.sendCustomCommand(extendedData, toUser, new IZegoIMSendCustomCommandCallback() {
            @Override
            public void onIMSendCustomCommandResult(int errorCode) {
                if (invitationCallback != null) {
                    List<String> errorInvitees = new ArrayList<>();
                    if (errorCode != 0) {
                        errorInvitees.add(targetUser.userID);
                    }
                    invitationCallback.onResult(errorCode, invitationID, errorInvitees);
                }
            }
        });
    }

    @Override
    public void acceptInvite(ZEGOInvitation invitation, AcceptInvitationCallback callback) {
        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        ZEGOLiveUser localUser = rtcService.getLocalUser();
        ZEGOLiveUser targetUser = rtcService.getUser(invitation.inviter);
        if (localUser == null || targetUser == null) {
            return;
        }
        ArrayList<ZegoUser> toUser = new ArrayList<>();
        toUser.add(new ZegoUser(targetUser.userID, targetUser.userName));

        String extendedData = invitation.extendedData;
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol.isRequest()) {
            protocol.setActionType(CoHostProtocol.HostAcceptAudienceCoHostApply);
        } else {
            protocol.setActionType(CoHostProtocol.AudienceAcceptCoHostInvitation);
        }
        JSONObject jsonObject = null;
        try {
            jsonObject = new JSONObject(protocol.toString());
            jsonObject.put("invitationID", invitation.invitationID);
        } catch (JSONException e) {

        }
        if (jsonObject != null) {
            extendedData = jsonObject.toString();
        }
        rtcService.sendCustomCommand(extendedData, toUser, new IZegoIMSendCustomCommandCallback() {
            @Override
            public void onIMSendCustomCommandResult(int errorCode) {
                if (callback != null) {
                    callback.onResult(errorCode, invitation.invitationID);
                }
            }
        });
    }

    @Override
    public void rejectInvite(ZEGOInvitation invitation, RejectInvitationCallback callback) {
        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        ZEGOLiveUser localUser = rtcService.getLocalUser();
        ZEGOLiveUser targetUser = rtcService.getUser(invitation.inviter);
        if (localUser == null || targetUser == null) {
            return;
        }

        ArrayList<ZegoUser> toUser = new ArrayList<>();
        toUser.add(new ZegoUser(targetUser.userID, targetUser.userName));

        String extendedData = invitation.extendedData;
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol.isRequest()) {
            protocol.setActionType(CoHostProtocol.HostRefuseAudienceCoHostApply);
        } else {
            protocol.setActionType(CoHostProtocol.AudienceRefuseCoHostInvitation);
        }
        JSONObject jsonObject = null;
        try {
            jsonObject = new JSONObject(protocol.toString());
            jsonObject.put("invitationID", invitation.invitationID);
        } catch (JSONException e) {

        }
        if (jsonObject != null) {
            extendedData = jsonObject.toString();
        }

        rtcService.sendCustomCommand(extendedData, toUser, new IZegoIMSendCustomCommandCallback() {
            @Override
            public void onIMSendCustomCommandResult(int errorCode) {
                if (callback != null) {
                    callback.onResult(errorCode, invitation.invitationID);
                }
            }
        });
    }


    @Override
    public void cancelInvite(ZEGOInvitation invitation, CancelInvitationCallback callback) {
        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        ZEGOLiveUser localUser = rtcService.getLocalUser();
        ZEGOLiveUser targetUser = rtcService.getUser(invitation.invitees.get(0));
        if (localUser == null || targetUser == null) {
            return;
        }
        ArrayList<ZegoUser> toUser = new ArrayList<>();
        toUser.add(new ZegoUser(targetUser.userID, targetUser.userName));

        String extendedData = invitation.extendedData;
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol.isRequest()) {
            protocol.setActionType(CoHostProtocol.AudienceCancelCoHostApply);
        } else {
            protocol.setActionType(CoHostProtocol.HostCancelCoHostInvitation);
        }
        JSONObject jsonObject = null;
        try {
            jsonObject = new JSONObject(protocol.toString());
            jsonObject.put("invitationID", invitation.invitationID);
        } catch (JSONException e) {

        }
        if (jsonObject != null) {
            extendedData = jsonObject.toString();
        }

        rtcService.sendCustomCommand(extendedData, toUser, new IZegoIMSendCustomCommandCallback() {
            @Override
            public void onIMSendCustomCommandResult(int errorCode) {
                if (callback != null) {
                    List<String> errorInvitees = new ArrayList<>();
                    if (errorCode != 0) {
                        errorInvitees.add(targetUser.userID);
                    }
                    callback.onResult(errorCode, invitation.invitationID, errorInvitees);
                }
            }
        });
    }

    @Override
    public void setInvitationListener(InvitationListener listener) {
        this.invitationListener = listener;
    }

    private static String generateRandomString() {
        StringBuilder builder = new StringBuilder();
        Random random = new Random();
        while (builder.length() < 6) {
            int nextInt = random.nextInt(10);
            if (builder.length() == 0 && nextInt == 0) {
                continue;
            }
            builder.append(nextInt);
        }
        return builder.toString();
    }
}
