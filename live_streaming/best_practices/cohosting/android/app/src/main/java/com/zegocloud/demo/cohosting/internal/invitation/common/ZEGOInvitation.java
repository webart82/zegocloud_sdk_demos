package com.zegocloud.demo.cohosting.internal.invitation.common;

import java.util.List;
import java.util.Map;

public class ZEGOInvitation {

    public String invitationID;
    public List<String> invitees;
    public String inviter;
    public String extendedData;
    public Map<String, ZEGOInviteeState> inviteeStateMap;
    protected ZEGOInvitationState lastState;
    protected ZEGOInvitationState state;

    public void setState(ZEGOInvitationState state) {
        lastState = this.state;
        this.state = state;
    }

    public boolean isFinished() {
        return state != ZEGOInvitationState.SEND_NEW && state != ZEGOInvitationState.RECV_NEW;
    }

    @Override
    public String toString() {
        return "ZEGOInvitation{" +
            "invitationID='" + invitationID + '\'' +
            ", invitees=" + invitees +
            ", inviter='" + inviter + '\'' +
            ", extendedData='" + extendedData + '\'' +
            '}';
    }
}
