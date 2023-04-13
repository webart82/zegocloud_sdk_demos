package com.zegocloud.demo.cohosting.internal.invitation.common;

import android.app.Application;

public interface InvitationInterface {

    void initSDK(Application application, long appID, String appSign);

    void connectUser(String userID, String userName, ConnectCallback callback);

    void disconnectUser();

    void joinRoom(String roomID);

    void leaveRoom();

    void inviteUser(String userID, String extendedData, SendInvitationCallback invitationCallback);

    void acceptInvite(ZEGOInvitation invitation, AcceptInvitationCallback callback);

    void rejectInvite(ZEGOInvitation invitation, RejectInvitationCallback callback);

    void cancelInvite(ZEGOInvitation invitation, CancelInvitationCallback callback);

    void setInvitationListener(InvitationListener listener);
}
