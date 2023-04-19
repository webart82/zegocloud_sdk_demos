package com.zegocloud.demo.cohosting.internal.invitation.common;

public interface IncomingInvitationListener {

    void onReceiveNewInvitation(String invitationID, String userID, String extendedData);

    void onReceiveInvitationButResponseTimeout(String invitationID);

    void onReceiveInvitationButIsCancelled(String invitationID, String inviter, String extendedData);

    void onActionAcceptInvitation(int errorCode, String invitationID);

    void onActionRejectInvitation(int errorCode, String invitationID);
}
