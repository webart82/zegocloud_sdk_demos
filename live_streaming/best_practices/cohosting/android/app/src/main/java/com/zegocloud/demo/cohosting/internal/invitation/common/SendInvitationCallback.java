package com.zegocloud.demo.cohosting.internal.invitation.common;

import java.util.List;

public interface SendInvitationCallback {

    void onResult(int errorCode, String invitationID, List<String> errorInvitees);
}
