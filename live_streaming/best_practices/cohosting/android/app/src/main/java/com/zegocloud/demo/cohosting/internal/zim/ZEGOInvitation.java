package com.zegocloud.demo.cohosting.internal.zim;

import java.util.List;

public class ZEGOInvitation {

    public String callID;
    public List<String> invitees;
    public String inviter;
    public String inviteExtendedData;
    protected ZEGOInviteState lastState;
    protected ZEGOInviteState state;


    public void setState(ZEGOInviteState state) {
        lastState = this.state;
        this.state = state;
    }

    public boolean isFinished() {
        return state != ZEGOInviteState.SEND_NEW && state != ZEGOInviteState.RECV_NEW;
    }
}
