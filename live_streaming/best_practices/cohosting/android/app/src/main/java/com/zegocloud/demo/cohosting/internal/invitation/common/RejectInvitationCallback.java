package com.zegocloud.demo.cohosting.internal.invitation.common;

public interface RejectInvitationCallback {

    void onResult(int errorCode, String invitationID);
}
