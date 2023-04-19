package com.zegocloud.demo.cohosting.internal.invitation.common;

import java.util.List;

public interface InvitationListener {

    void onInComingNewInvitation(String invitationID, String inviterID, String extendedData);

    void onInComingInvitationButResponseTimeout(String invitationID);

    void onInComingInvitationButIsCancelled(String invitationID, String inviterID, String extendedData);

    void onOutgoingInvitationButReceiveResponseTimeout(String invitationID, List<String> invitees);

    void onOutgoingInvitationAndIsAccepted(String invitationID, String invitee, String extendedData);

    void onOutgoingInvitationButIsRejected(String invitationID, String invitee, String extendedData);
}
