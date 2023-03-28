package com.zegocloud.demo.callwithinvitation.call;

import android.Manifest.permission;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.permissionx.guolindev.PermissionX;
import com.permissionx.guolindev.callback.RequestCallback;
import com.zegocloud.demo.callwithinvitation.ZEGOSDKManager;
import com.zegocloud.demo.callwithinvitation.internal.ZIMService.InvitationListener;
import com.zegocloud.demo.callwithinvitation.utils.ToastUtil;
import com.zegocloud.demo.callwithinvitation.R;
import com.zegocloud.demo.callwithinvitation.call.internal.CallInviteInfo;
import com.zegocloud.demo.callwithinvitation.databinding.ActivityCallWaitBinding;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zim.callback.ZIMCallAcceptanceSentCallback;
import im.zego.zim.callback.ZIMCallCancelSentCallback;
import im.zego.zim.callback.ZIMCallRejectionSentCallback;
import im.zego.zim.entity.ZIMError;
import im.zego.zim.enums.ZIMErrorCode;

public class CallWaitingActivity extends AppCompatActivity {

    public static void startActivity(Context context, CallInviteInfo callInviteInfo) {
        Intent intent = new Intent(context, CallWaitingActivity.class);
        intent.putExtra("callInviteInfo", callInviteInfo);
        context.startActivity(intent);
    }

    private ActivityCallWaitBinding binding;
    private CallInviteInfo callInviteInfo;
    private InvitationListener listener = new InvitationListener() {
        @Override
        public void onOutgoingCallInvitationAccepted(String callID, String invitee, String extendedData) {
            ZEGOSDKManager.getInstance().joinExpressRoom(callID, new IZegoRoomLoginCallback() {
                @Override
                public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                    if (errorCode == 0) {
                        finishAndExit();
                        CallingActivity.startActivity(CallWaitingActivity.this, callInviteInfo);
                    } else {
                        ToastUtil.show(CallWaitingActivity.this, "joinexpressRoom failed :" + errorCode);
                    }
                }
            });
        }

        @Override
        public void onOutgoingCallInvitationRejected(String callID, String invitee, String extendedData) {
            ToastUtil.show(CallWaitingActivity.this,"reject by user, extendedData:" + extendedData);
            finishAndExit();
        }

        @Override
        public void onOutgoingCallInvitationTimeout(String callID, ArrayList<String> invitees) {
            ToastUtil.show(CallWaitingActivity.this,"call invitation timeout");
            finishAndExit();
        }

        @Override
        public void onIncomingCallInvitationCancelled(String callID, String inviter, String extendedData) {
            finishAndExit();
            ToastUtil.show(CallWaitingActivity.this,"cancelled by user");
        }

        @Override
        public void onIncomingCallInvitationTimeout(String inviter) {
            finishAndExit();
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityCallWaitBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        callInviteInfo = (CallInviteInfo) getIntent().getSerializableExtra("callInviteInfo");

        if (callInviteInfo.isOutgoingCall) {
            binding.incomingCallAcceptButton.setVisibility(View.GONE);
            binding.incomingCallRejectButton.setVisibility(View.GONE);
            binding.outgoingCallCancelButton.setVisibility(View.VISIBLE);
        } else {
            binding.incomingCallAcceptButton.setVisibility(View.VISIBLE);
            binding.incomingCallRejectButton.setVisibility(View.VISIBLE);
            binding.outgoingCallCancelButton.setVisibility(View.GONE);
        }

        List<String> permissions;
        if (callInviteInfo.isVideoCall()) {
            permissions = Arrays.asList(permission.CAMERA, permission.RECORD_AUDIO);
        } else {
            permissions = Collections.singletonList(permission.RECORD_AUDIO);
        }
        requestPermissionIfNeeded(permissions, new RequestCallback() {
            @Override
            public void onResult(boolean allGranted, @NonNull List<String> grantedList,
                @NonNull List<String> deniedList) {
                if (allGranted) {
                    binding.videoView.startPreviewOnly();
                }
            }
        });

        if (callInviteInfo.isVideoCall()) {
            binding.incomingCallAcceptButton.setImageResource(R.drawable.icon_video_accept);
        } else {
            binding.incomingCallAcceptButton.setImageResource(R.drawable.icon_voice_accept);
        }

        ZEGOSDKManager.getInstance().addInvitationListener(listener);

        binding.incomingCallAcceptButton.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance().callAccept(callInviteInfo.callID, new ZIMCallAcceptanceSentCallback() {
                @Override
                public void onCallAcceptanceSent(String callID, ZIMError errorInfo) {
                    if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                        ZEGOSDKManager.getInstance().joinExpressRoom(callID, new IZegoRoomLoginCallback() {
                            @Override
                            public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                                if (errorCode == 0) {
                                    finishAndExit();
                                    CallingActivity.startActivity(CallWaitingActivity.this, callInviteInfo);
                                }
                            }
                        });
                    } else {
                        ToastUtil.show(CallWaitingActivity.this, "send invite failed :" + errorInfo.getCode());
                    }
                }
            });
        });
        binding.incomingCallRejectButton.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance().callReject(callInviteInfo.callID, new ZIMCallRejectionSentCallback() {
                @Override
                public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                    if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                        finishAndExit();
                    } else {
                        ToastUtil.show(CallWaitingActivity.this, "send reject failed :" + errorInfo.getCode());
                    }
                }
            });
        });

        binding.outgoingCallCancelButton.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance()
                .cancelInvite(callInviteInfo.calleeUserID, callInviteInfo.callID, new ZIMCallCancelSentCallback() {
                    @Override
                    public void onCallCancelSent(String callID, ArrayList<String> errorInvitees, ZIMError errorInfo) {
                        if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                            finishAndExit();
                        } else {
                            ToastUtil.show(CallWaitingActivity.this, "cancel invite failed :" + errorInfo.getCode());
                        }
                    }
                });
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ZEGOSDKManager.getInstance().removeInvitationListener(listener);
    }

    private void finishAndExit() {
        ZEGOSDKManager.getInstance().removeInvitationListener(listener);
        ZEGOSDKManager.getInstance().stopCameraPreview();
        finish();
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