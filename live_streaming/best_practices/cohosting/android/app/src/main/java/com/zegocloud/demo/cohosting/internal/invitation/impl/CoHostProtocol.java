package com.zegocloud.demo.cohosting.internal.invitation.impl;

import android.text.TextUtils;
import org.json.JSONException;
import org.json.JSONObject;

public class CoHostProtocol {

    // audience
    public static final int AudienceApplyToBecomeCoHost = 10000;
    public static final int AudienceCancelCoHostApply = 10001;
    public static final int HostRefuseAudienceCoHostApply = 10002;
    public static final int HostAcceptAudienceCoHostApply = 10003;
    // host
    public static final int HostInviteAudienceToBecomeCoHost = 10100;
    public static final int HostCancelCoHostInvitation = 10101;
    public static final int AudienceRefuseCoHostInvitation = 10102;
    public static final int AudienceAcceptCoHostInvitation = 10103;

    //

    private int actionType;
    private String operatorID;
    private String targetID;
    //    private JSONObject data;
    //    private boolean accept;
    //    private boolean apply;

    public static CoHostProtocol parse(String string) {
        if (TextUtils.isEmpty(string)) {
            return null;
        }
        CoHostProtocol protocol = new CoHostProtocol();
        try {
            JSONObject jsonObject = new JSONObject(string);
            protocol.actionType = getIntFromJson("actionType", jsonObject);
            protocol.operatorID = getStringFromJson("operatorID", jsonObject);
            protocol.targetID = getStringFromJson("targetID", jsonObject);
            //            data = getJsonObjectFromJson("data", jsonObject);
            //            apply = getBooleanFromJson("isApply", data);
            //            accept = getBooleanFromJson("isAccept", data);
        } catch (JSONException e) {
            protocol = null;
        }
        return protocol;
    }


    public String toString() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("actionType", actionType);
            jsonObject.put("operatorID", operatorID);
            jsonObject.put("targetID", targetID);
            //            jsonObject.put("data", data);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
        return jsonObject.toString();
    }

    private static int getIntFromJson(String key, JSONObject jsonObject) throws JSONException {
        if (jsonObject == null) {
            throw new JSONException("jsonObject is null");
        }
        int result = 0;
        if (jsonObject.has(key)) {
            result = jsonObject.getInt(key);
        }
        return result;
    }

    private static String getStringFromJson(String key, JSONObject jsonObject) throws JSONException {
        if (jsonObject == null) {
            throw new JSONException("jsonObject is null");
        }
        String result = null;
        if (jsonObject.has(key)) {
            result = jsonObject.getString(key);
        }
        return result;
    }

    private static boolean getBooleanFromJson(String key, JSONObject jsonObject) throws JSONException {
        if (jsonObject == null) {
            throw new JSONException("jsonObject is null");
        }
        boolean result = false;
        if (jsonObject.has(key)) {
            result = jsonObject.getBoolean(key);
        }
        return result;
    }

    private static JSONObject getJsonObjectFromJson(String key, JSONObject jsonObject) throws JSONException {
        if (jsonObject == null) {
            throw new JSONException("jsonObject is null");
        }
        JSONObject result = null;
        if (jsonObject.has(key)) {
            result = jsonObject.getJSONObject(key);
        }
        return result;
    }

    public boolean isRequest() {
        return actionType == AudienceApplyToBecomeCoHost;
    }

    public boolean isInvite() {
        return actionType == HostInviteAudienceToBecomeCoHost;
    }

    public boolean isCancelRequest() {
        return actionType == AudienceCancelCoHostApply;
    }

    public boolean isCancelInvite() {
        return actionType == HostCancelCoHostInvitation;
    }

    public boolean isRefuseRequest() {
        return actionType == HostRefuseAudienceCoHostApply;
    }

    public boolean isRefuseInvite() {
        return actionType == AudienceRefuseCoHostInvitation;
    }

    public boolean isAcceptRequest() {
        return actionType == HostAcceptAudienceCoHostApply;
    }

    public boolean isAcceptInvite() {
        return actionType == AudienceAcceptCoHostInvitation;
    }

    public int getActionType() {
        return actionType;
    }

    public void setActionType(int actionType) {
        this.actionType = actionType;
    }

    public String getOperatorID() {
        return operatorID;
    }

    public void setOperatorID(String operatorID) {
        this.operatorID = operatorID;
    }

    public String getTargetID() {
        return targetID;
    }

    public void setTargetID(String targetID) {
        this.targetID = targetID;
    }
}


