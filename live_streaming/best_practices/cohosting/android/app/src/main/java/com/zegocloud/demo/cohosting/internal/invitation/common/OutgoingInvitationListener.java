package com.zegocloud.demo.cohosting.internal.invitation.common;

import java.util.List;

public interface OutgoingInvitationListener {

    void onActionSendInvitation(int errorCode, String invitationID, String extendedData, List<String> errorInvitees);

    void onActionCancelInvitation(int errorCode, String invitationID, List<String> errorInvitees);

    void onSendInvitationButReceiveResponseTimeout(String invitationID, List<String> invitees);

    void onSendInvitationAndIsAccepted(String invitationID, String invitee, String extendedData);

    void onSendInvitationButIsRejected(String invitationID, String invitee, String extendedData);

}
