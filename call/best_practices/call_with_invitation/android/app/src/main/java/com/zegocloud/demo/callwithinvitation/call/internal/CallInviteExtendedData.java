package com.zegocloud.demo.callwithinvitation.call.internal;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

public class CallInviteExtendedData {

    public String type;
    public String callerUserName;

    public static final String TYPE_VIDEO_CALL = "video_call";
    public static final String TYPE_VOICE_CALL = "voice_call";

    public static String getExtendedDataString(CallInviteExtendedData extendedData) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("type", extendedData.type);
            jsonObject.put("userName", extendedData.callerUserName);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject.toString();
    }

    public boolean isVideoCall() {
        return TYPE_VIDEO_CALL.equals(type);
    }

    @NonNull
    @Override
    public String toString() {
        return getExtendedDataString(this);
    }

    public static CallInviteExtendedData parseExtendedData(String extendedData) {
        if (extendedData == null || extendedData.isEmpty()) {
            return null;
        }
        try {
            JSONObject jsonObject = new JSONObject(extendedData);
            if (jsonObject.has("type")) {
                String type = jsonObject.getString("type");
                String userName = jsonObject.getString("userName");
                CallInviteExtendedData data = new CallInviteExtendedData();
                data.type = type;
                data.callerUserName = userName;
                return data;
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return null;
    }
}
