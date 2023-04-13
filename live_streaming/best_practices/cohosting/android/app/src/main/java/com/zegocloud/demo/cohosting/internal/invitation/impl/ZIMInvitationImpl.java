package com.zegocloud.demo.cohosting.internal.invitation.impl;

import android.app.Application;
import android.util.Log;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.invitation.common.AcceptInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.CancelInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ConnectCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.InvitationInterface;
import com.zegocloud.demo.cohosting.internal.invitation.common.InvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.RejectInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.SendInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import im.zego.zim.ZIM;
import im.zego.zim.callback.ZIMEventHandler;
import im.zego.zim.callback.ZIMLoggedInCallback;
import im.zego.zim.callback.ZIMMessageSentCallback;
import im.zego.zim.callback.ZIMRoomEnteredCallback;
import im.zego.zim.callback.ZIMRoomLeftCallback;
import im.zego.zim.entity.ZIMAppConfig;
import im.zego.zim.entity.ZIMCommandMessage;
import im.zego.zim.entity.ZIMError;
import im.zego.zim.entity.ZIMMessage;
import im.zego.zim.entity.ZIMMessageSendConfig;
import im.zego.zim.entity.ZIMRoomAdvancedConfig;
import im.zego.zim.entity.ZIMRoomFullInfo;
import im.zego.zim.entity.ZIMRoomInfo;
import im.zego.zim.entity.ZIMUserInfo;
import im.zego.zim.enums.ZIMConversationType;
import im.zego.zim.enums.ZIMErrorCode;
import im.zego.zim.enums.ZIMMessageType;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.atomic.AtomicBoolean;

public class ZIMInvitationImpl implements InvitationInterface {

    private Application application;
    private final AtomicBoolean isZIMInited = new AtomicBoolean();
    private ZIM zim;
    private String mRoomID;
    private static final String TAG = "ZIMInvitationImpl";
    private InvitationListener invitationListener;

    @Override
    public void initSDK(Application application, long appID, String appSign) {
        this.application = application;
        boolean result = isZIMInited.compareAndSet(false, true);
        if (!result) {
            return;
        }
        ZIMAppConfig zimAppConfig = new ZIMAppConfig();
        zimAppConfig.appID = appID;
        zimAppConfig.appSign = appSign;
        zim = ZIM.create(zimAppConfig, application);

        zim.setEventHandler(new ZIMEventHandler() {
            @Override
            public void onReceiveRoomMessage(ZIM zim, ArrayList<ZIMMessage> messageList, String fromRoomID) {
                super.onReceiveRoomMessage(zim, messageList, fromRoomID);

                for (ZIMMessage zimMessage : messageList) {
                    if (zimMessage.getType() == ZIMMessageType.COMMAND) {
                        ZIMCommandMessage commandMessage = (ZIMCommandMessage) zimMessage;
                        String message = new String(commandMessage.message, StandardCharsets.UTF_8);
                        Log.d(TAG, "onReceiveRoomMessage,message: " + message);
                        Log.d(TAG, "onReceiveRoomMessage,extendedData: " + commandMessage.extendedData);
                        CoHostProtocol protocol = CoHostProtocol.parse(message);
                        if (invitationListener == null) {
                            return;
                        }
                        if (protocol != null) {
                            String operatorID = protocol.getOperatorID();
                            if (protocol.isInvite() || protocol.isRequest()) {
                                invitationListener.onInComingNewInvitation(String.valueOf(commandMessage.getMessageID()), operatorID,
                                    message);
                            } else if (protocol.isCancelInvite() || protocol.isCancelRequest()) {
                                invitationListener.onInComingInvitationButIsCancelled(commandMessage.extendedData, operatorID,
                                    message);
                            } else if (protocol.isRefuseInvite() || protocol.isRefuseRequest()) {
                                invitationListener.onOutgoingInvitationButIsRejected(commandMessage.extendedData, operatorID, message);
                            } else if (protocol.isAcceptInvite() || protocol.isAcceptRequest()) {
                                invitationListener.onOutgoingInvitationAndIsAccepted(commandMessage.extendedData, operatorID, message);
                            }
                        }
                    }
                }
            }
        });
    }

    @Override
    public void connectUser(String userID, String userName, ConnectCallback callback) {
        ZIMUserInfo zimUserInfo = new ZIMUserInfo();
        zimUserInfo.userID = userID;
        zimUserInfo.userName = userName;

        if (zim == null) {
            return;
        }
        zim.login(zimUserInfo, "", new ZIMLoggedInCallback() {

            public void onLoggedIn(ZIMError errorInfo) {
                if (callback != null) {
                    int code = errorInfo.code == ZIMErrorCode.USER_HAS_ALREADY_LOGGED ? ZIMErrorCode.SUCCESS.value()
                        : errorInfo.code.value();
                    callback.onResult(code, errorInfo.message);
                }
            }
        });
    }

    @Override
    public void disconnectUser() {
        if (zim == null) {
            return;
        }
        zim.logout();
    }

    @Override
    public void joinRoom(String roomID) {
        if (zim == null) {
            return;
        }
        ZIMRoomInfo zimRoomInfo = new ZIMRoomInfo();
        zimRoomInfo.roomID = roomID;
        ZIMRoomAdvancedConfig config = new ZIMRoomAdvancedConfig();
        if (ZIM.getInstance() == null) {
            return;
        }
        ZIM.getInstance().enterRoom(zimRoomInfo, config, new ZIMRoomEnteredCallback() {

            public void onRoomEntered(ZIMRoomFullInfo roomInfo, ZIMError errorInfo) {
                if (errorInfo.code == ZIMErrorCode.SUCCESS) {
                    mRoomID = roomID;
                }
                //                if (callback != null) {
                //                    callback.onResult(errorInfo.code.value(), errorInfo.message);
                //                }
            }
        });
    }

    @Override
    public void leaveRoom() {
        if (zim == null) {
            return;
        }
        zim.leaveRoom(mRoomID, new ZIMRoomLeftCallback() {
            @Override
            public void onRoomLeft(String roomID, ZIMError errorInfo) {

            }
        });
    }

    @Override
    public void inviteUser(String userID, String extendedData, SendInvitationCallback invitationCallback) {
        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        ZEGOLiveUser localUser = rtcService.getLocalUser();
        ZEGOLiveUser targetUser = rtcService.getUser(userID);
        if (localUser == null || targetUser == null) {
            return;
        }
        if (zim == null) {
            return;
        }
        byte[] bytes = extendedData.getBytes(StandardCharsets.UTF_8);
        ZIMCommandMessage commandMessage = new ZIMCommandMessage(bytes);
        ZIMMessageSendConfig config = new ZIMMessageSendConfig();

        zim.sendMessage(commandMessage, mRoomID, ZIMConversationType.ROOM, config, new ZIMMessageSentCallback() {
            @Override
            public void onMessageAttached(ZIMMessage message) {
            }

            @Override
            public void onMessageSent(ZIMMessage message, ZIMError errorInfo) {
                if (invitationCallback != null) {
                    List<String> errorInvitees = new ArrayList<>();
                    if (errorInfo.code != ZIMErrorCode.SUCCESS) {
                        errorInvitees.add(userID);
                    }
                    invitationCallback.onResult(errorInfo.code.value(), String.valueOf(message.getMessageID()),
                        errorInvitees);
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
        if (zim == null) {
            return;
        }
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol.isRequest()) {
            protocol.setActionType(CoHostProtocol.HostAcceptAudienceCoHostApply);
        } else {
            protocol.setActionType(CoHostProtocol.AudienceAcceptCoHostInvitation);
        }
        byte[] bytes = protocol.toString().getBytes(StandardCharsets.UTF_8);
        ZIMCommandMessage commandMessage = new ZIMCommandMessage(bytes);
        commandMessage.extendedData = invitation.invitationID;
        ZIMMessageSendConfig config = new ZIMMessageSendConfig();

        zim.sendMessage(commandMessage, mRoomID, ZIMConversationType.ROOM, config, new ZIMMessageSentCallback() {
            @Override
            public void onMessageAttached(ZIMMessage message) {

            }

            @Override
            public void onMessageSent(ZIMMessage message, ZIMError errorInfo) {
                if (callback != null) {
                    callback.onResult(errorInfo.code.value(), invitation.invitationID);
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
        if (zim == null) {
            return;
        }
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol.isRequest()) {
            protocol.setActionType(CoHostProtocol.HostRefuseAudienceCoHostApply);
        } else {
            protocol.setActionType(CoHostProtocol.AudienceRefuseCoHostInvitation);
        }
        byte[] bytes = protocol.toString().getBytes(StandardCharsets.UTF_8);
        ZIMCommandMessage commandMessage = new ZIMCommandMessage(bytes);
        commandMessage.extendedData = invitation.invitationID;
        ZIMMessageSendConfig config = new ZIMMessageSendConfig();

        zim.sendMessage(commandMessage, mRoomID, ZIMConversationType.ROOM, config, new ZIMMessageSentCallback() {
            @Override
            public void onMessageAttached(ZIMMessage message) {

            }

            @Override
            public void onMessageSent(ZIMMessage message, ZIMError errorInfo) {
                if (callback != null) {
                    callback.onResult(errorInfo.code.value(), invitation.invitationID);
                }
            }
        });
    }

    @Override
    public void cancelInvite(ZEGOInvitation invitation, CancelInvitationCallback callback) {
        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        ZEGOLiveUser localUser = rtcService.getLocalUser();
        ZEGOLiveUser targetUser = rtcService.getUser(invitation.inviter);
        if (localUser == null || targetUser == null) {
            return;
        }
        if (zim == null) {
            return;
        }
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol.isRequest()) {
            protocol.setActionType(CoHostProtocol.AudienceCancelCoHostApply);
        } else {
            protocol.setActionType(CoHostProtocol.HostCancelCoHostInvitation);
        }
        byte[] bytes = protocol.toString().getBytes(StandardCharsets.UTF_8);
        ZIMCommandMessage commandMessage = new ZIMCommandMessage(bytes);
        commandMessage.extendedData = invitation.invitationID;
        ZIMMessageSendConfig config = new ZIMMessageSendConfig();

        zim.sendMessage(commandMessage, mRoomID, ZIMConversationType.ROOM, config, new ZIMMessageSentCallback() {
            @Override
            public void onMessageAttached(ZIMMessage message) {

            }

            @Override
            public void onMessageSent(ZIMMessage message, ZIMError errorInfo) {
                if (callback != null) {
                    List<String> errorInvitees = new ArrayList<>();
                    if (errorInfo.code != ZIMErrorCode.SUCCESS) {
                        errorInvitees.add(targetUser.userID);
                    }
                    callback.onResult(errorInfo.code.value(), invitation.invitationID, errorInvitees);
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
