package com.zegocloud.demo.callwithinvitation.call.internal;

import java.io.Serializable;

public class CallInviteInfo implements Serializable {

    public String callID;
    public String callerUserID;
    public String callerUserName;
    public String calleeUserID;
    public String callType;
    public boolean isOutgoingCall;

    public boolean isVideoCall() {
        return CallInviteExtendedData.TYPE_VIDEO_CALL.equals(callType);
    }
}
