package com.zegocloud.demo.callwithinvitation;

import android.Manifest.permission;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.permissionx.guolindev.PermissionX;
import com.permissionx.guolindev.callback.RequestCallback;
import com.zegocloud.demo.callwithinvitation.databinding.ActivityMainBinding;
import com.zegocloud.demo.callwithinvitation.internal.ZIMService.ConnectionStateChangeListener;
import com.zegocloud.demo.callwithinvitation.utils.ToastUtil;
import com.zegocloud.demo.callwithinvitation.call.CallBackgroundService;
import com.zegocloud.demo.callwithinvitation.call.CallWaitingActivity;
import com.zegocloud.demo.callwithinvitation.call.internal.CallInviteExtendedData;
import com.zegocloud.demo.callwithinvitation.call.internal.CallInviteInfo;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Random;

import im.zego.zim.ZIM;
import im.zego.zim.callback.ZIMCallInvitationSentCallback;
import im.zego.zim.entity.ZIMCallInvitationSentInfo;
import im.zego.zim.entity.ZIMCallUserInfo;
import im.zego.zim.entity.ZIMError;
import im.zego.zim.enums.ZIMConnectionEvent;
import im.zego.zim.enums.ZIMConnectionState;
import im.zego.zim.enums.ZIMErrorCode;

public class HomeActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    private String userID = generateUserID();
    private String userName = userID + "_" + Build.MANUFACTURER.toLowerCase();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        binding.userId.setText(userID);

        binding.callNewVideo.setOnClickListener(v -> {
            CallInviteExtendedData data = new CallInviteExtendedData();
            data.type = CallInviteExtendedData.TYPE_VIDEO_CALL;
            data.callerUserName = userName;
            callUser(data);
        });
        binding.callNewVoice.setOnClickListener(v -> {
            CallInviteExtendedData data = new CallInviteExtendedData();
            data.type = CallInviteExtendedData.TYPE_VOICE_CALL;
            data.callerUserName = userName;
            callUser(data);
        });

        initAndSignInZEGOSDK();
    }

    private void callUser(CallInviteExtendedData callInviteExtendedData) {
        String targetUserID = binding.callTargetUserId.getEditText().getText().toString();
        if (TextUtils.isEmpty(targetUserID)) {
            binding.callTargetUserId.setError("please input targetUserID");
            return;
        }
        List<String> permissions;
        if (callInviteExtendedData.isVideoCall()) {
            permissions = Arrays.asList(permission.CAMERA, permission.RECORD_AUDIO);
        } else {
            permissions = Collections.singletonList(permission.RECORD_AUDIO);
        }
        requestPermissionIfNeeded(permissions, new RequestCallback() {
            @Override
            public void onResult(boolean allGranted, @NonNull List<String> grantedList,
                @NonNull List<String> deniedList) {
                if (allGranted) {
                    callUserInner(targetUserID, callInviteExtendedData);
                }
            }
        });
    }

    private void callUserInner(String targetUserID, CallInviteExtendedData callInviteExtendedData) {
        if (!ZEGOSDKManager.getInstance().isIMUserConnected()) {
            return;
        }

        ZEGOSDKManager.getInstance()
            .inviteUser(targetUserID, callInviteExtendedData.toString(), new ZIMCallInvitationSentCallback() {
                @Override
                public void onCallInvitationSent(String callID, ZIMCallInvitationSentInfo info, ZIMError errorInfo) {
                    if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                        if (info.errorInvitees.isEmpty()) {
                            CallInviteInfo inviteInfo = new CallInviteInfo();
                            inviteInfo.callID = callID;
                            inviteInfo.callerUserID = userID;
                            inviteInfo.callerUserName = callInviteExtendedData.callerUserName;
                            inviteInfo.calleeUserID = targetUserID;
                            inviteInfo.callType = callInviteExtendedData.type;
                            inviteInfo.isOutgoingCall = true;
                            CallWaitingActivity.startActivity(HomeActivity.this, inviteInfo);
                        } else {
                            for (ZIMCallUserInfo errorInvitee : info.errorInvitees) {
                                if (Objects.equals(errorInvitee.userID, targetUserID)) {
                                    ToastUtil.show(HomeActivity.this,
                                        "call user failed,user " + targetUserID + " is " + errorInvitee.state);
                                }
                            }
                        }
                    } else {
                        ToastUtil.show(HomeActivity.this, "call user failed,errorCode: " + errorInfo.getCode());
                    }
                }
            });
    }

    private void initAndSignInZEGOSDK() {
        ZEGOSDKManager.getInstance().initSDK(getApplication(), ZEGOSDKKeyCenter.appID, ZEGOSDKKeyCenter.appSign);
        ZEGOSDKManager.getInstance().connectUser(userID, userName, errorInfo -> {
            if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                Intent intent = new Intent(this, CallBackgroundService.class);
                startService(intent);
            } else {
                ToastUtil.show(HomeActivity.this, "loginZIMSDK failed,errorCode: " + errorInfo.getCode());
            }
        });

        ZEGOSDKManager.getInstance().addIMConnectionStateChangeListener(new ConnectionStateChangeListener() {
            @Override
            public void onConnectionStateChanged(ZIM zim, ZIMConnectionState state, ZIMConnectionEvent event,
                JSONObject extendedData) {
                // TODO
            }
        });
    }

    private static String generateUserID() {
        StringBuilder builder = new StringBuilder();
        Random random = new Random();
        while (builder.length() < 6) {
            int nextInt = random.nextInt(10);
            if (builder.length() == 0 && nextInt == 0) {
                continue;
            }
            builder.append(nextInt);
        }
        return builder.toString();
    }

    private void requestPermissionIfNeeded(List<String> permissions, RequestCallback requestCallback) {
        boolean allGranted = true;
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                allGranted = false;
            }
        }
        if (allGranted) {
            requestCallback.onResult(true, permissions, new ArrayList<>());
            return;
        }

        PermissionX.init(this).permissions(permissions).onExplainRequestReason((scope, deniedList) -> {
            String message = "";
            if (permissions.size() == 1) {
                if (deniedList.contains(permission.CAMERA)) {
                    message = this.getString(R.string.permission_explain_camera);
                } else if (deniedList.contains(permission.RECORD_AUDIO)) {
                    message = this.getString(R.string.permission_explain_mic);
                }
            } else {
                if (deniedList.size() == 1) {
                    if (deniedList.contains(permission.CAMERA)) {
                        message = this.getString(R.string.permission_explain_camera);
                    } else if (deniedList.contains(permission.RECORD_AUDIO)) {
                        message = this.getString(R.string.permission_explain_mic);
                    }
                } else {
                    message = this.getString(R.string.permission_explain_camera_mic);
                }
            }
            scope.showRequestReasonDialog(deniedList, message, getString(R.string.ok));
        }).onForwardToSettings((scope, deniedList) -> {
            String message = "";
            if (permissions.size() == 1) {
                if (deniedList.contains(permission.CAMERA)) {
                    message = this.getString(R.string.settings_camera);
                } else if (deniedList.contains(permission.RECORD_AUDIO)) {
                    message = this.getString(R.string.settings_mic);
                }
            } else {
                if (deniedList.size() == 1) {
                    if (deniedList.contains(permission.CAMERA)) {
                        message = this.getString(R.string.settings_camera);
                    } else if (deniedList.contains(permission.RECORD_AUDIO)) {
                        message = this.getString(R.string.settings_mic);
                    }
                } else {
                    message = this.getString(R.string.settings_camera_mic);
                }
            }
            scope.showForwardToSettingsDialog(deniedList, message, getString(R.string.settings),
                getString(R.string.cancel));
        }).request(new RequestCallback() {
            @Override
            public void onResult(boolean allGranted, @NonNull List<String> grantedList,
                @NonNull List<String> deniedList) {
                if (requestCallback != null) {
                    requestCallback.onResult(allGranted, grantedList, deniedList);
                }
            }
        });
    }
}