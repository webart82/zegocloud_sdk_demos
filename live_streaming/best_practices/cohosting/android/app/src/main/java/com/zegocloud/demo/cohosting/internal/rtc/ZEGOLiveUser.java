package com.zegocloud.demo.cohosting.internal.rtc;

import android.text.TextUtils;
import android.util.Log;
import java.util.Objects;

public class ZEGOLiveUser {

    public String userID;
    public String userName;
    private String mainStreamID;
    private String shareStreamID;
    private ZEGOLiveRole role;

    public ZEGOLiveUser(String userID, String userName) {
        this.userID = userID;
        this.userName = userName;
        role = ZEGOLiveRole.AUDIENCE;
    }

    public String getMainStreamID() {
        return mainStreamID;
    }

    public boolean hasStream() {
        return !TextUtils.isEmpty(mainStreamID) && !TextUtils.isEmpty(shareStreamID);
    }

    private static final String TAG = "ZEGOLiveUser";
    public void setStreamID(String streamID) {
        Log.d(TAG, "setStreamID() called with: streamID = [" + streamID + "]");
        if (streamID.contains("main")) {
            this.mainStreamID = streamID;
        } else if (streamID.contains("share")) {
            this.shareStreamID = streamID;
        }
        if (!TextUtils.isEmpty(mainStreamID)) {
            if (mainStreamID.endsWith("_host")) {
                role = ZEGOLiveRole.HOST;
            } else if (streamID.endsWith("_cohost")) {
                role = ZEGOLiveRole.CO_HOST;
            }
        }
    }

    public void deleteStream(String streamID) {
        if (streamID.contains("main")) {
            mainStreamID = null;
        } else {
            shareStreamID = null;
        }
        if (TextUtils.isEmpty(mainStreamID) && TextUtils.isEmpty(shareStreamID)) {
            role = ZEGOLiveRole.AUDIENCE;
        }
    }

    public String getShareStreamID() {
        return shareStreamID;
    }

    public ZEGOLiveRole getRole() {
        return role;
    }

    public void setRole(ZEGOLiveRole role) {
        this.role = role;
    }

    public boolean isHost() {
        return role == ZEGOLiveRole.HOST;
    }

    public boolean isCoHost() {
        return role == ZEGOLiveRole.CO_HOST;
    }

    public boolean isAudience() {
        return role == ZEGOLiveRole.AUDIENCE;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        ZEGOLiveUser userInfo = (ZEGOLiveUser) o;
        return Objects.equals(userID, userInfo.userID);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userID);
    }

    @Override
    public String toString() {
        return "ZEGOLiveUser{" +
            "userID='" + userID + '\'' +
            ", userName='" + userName + '\'' +
            ", mainStreamID='" + mainStreamID + '\'' +
            ", shareStreamID='" + shareStreamID + '\'' +
            ", role=" + role +
            '}';
    }
}
