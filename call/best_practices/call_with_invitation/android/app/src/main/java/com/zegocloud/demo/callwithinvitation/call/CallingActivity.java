package com.zegocloud.demo.callwithinvitation.call;

import android.Manifest.permission;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.permissionx.guolindev.PermissionX;
import com.permissionx.guolindev.callback.RequestCallback;
import com.zegocloud.demo.callwithinvitation.ZEGOSDKManager;
import com.zegocloud.demo.callwithinvitation.utils.ToastUtil;
import com.zegocloud.demo.callwithinvitation.R;
import com.zegocloud.demo.callwithinvitation.call.internal.CallInviteInfo;
import com.zegocloud.demo.callwithinvitation.databinding.ActivityCallBinding;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.constants.ZegoRemoteDeviceState;
import im.zego.zegoexpress.constants.ZegoRoomStateChangedReason;
import im.zego.zegoexpress.constants.ZegoUpdateType;
import im.zego.zegoexpress.entity.ZegoStream;
import im.zego.zegoexpress.entity.ZegoUser;

public class CallingActivity extends AppCompatActivity {

    private ActivityCallBinding binding;
    private CallInviteInfo callInviteInfo;

    public static void startActivity(Context context, CallInviteInfo callInviteInfo) {
        Intent intent = new Intent(context, CallingActivity.class);
        intent.putExtra("callInviteInfo", callInviteInfo);
        context.startActivity(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityCallBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        callInviteInfo = (CallInviteInfo) getIntent().getSerializableExtra("callInviteInfo");

        listenExpressEvent();

        binding.callCameraSwitchBtn.setState(true);
        binding.callCameraBtn.setState(callInviteInfo.isVideoCall());

        binding.callHangupBtn.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance().leaveExpressRoom();
            finish();
        });

        binding.callMicBtn.setState(true);
        binding.callSpeakerBtn.setState(true);

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
                // my video show in small view
                if (callInviteInfo.isOutgoingCall) {
                    binding.smallVideoView.setUserID(callInviteInfo.callerUserID);
                    binding.fullVideoView.setUserID(callInviteInfo.calleeUserID);
                } else {
                    binding.smallVideoView.setUserID(callInviteInfo.calleeUserID);
                    binding.fullVideoView.setUserID(callInviteInfo.callerUserID);
                }
            }
        });

        binding.smallVideoView.setOnClickListener(v -> {
            String fullVideoViewUserID = binding.fullVideoView.getUserID();
            String smallVideoViewUserID = binding.smallVideoView.getUserID();
            binding.fullVideoView.setUserID(smallVideoViewUserID);
            binding.smallVideoView.setUserID(fullVideoViewUserID);
        });
        binding.fullVideoView.setOnClickListener(v -> {
            String fullVideoViewUserID = binding.fullVideoView.getUserID();
            String smallVideoViewUserID = binding.smallVideoView.getUserID();
            binding.fullVideoView.setUserID(smallVideoViewUserID);
            binding.smallVideoView.setUserID(fullVideoViewUserID);
        });
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (isFinishing()) {
            ZEGOSDKManager.getInstance().leaveExpressRoom();
            ZEGOSDKManager.getInstance().setExpressEventHandler(null);
        }
    }

    public void listenExpressEvent() {
        ZEGOSDKManager.getInstance().setExpressEventHandler(new IZegoEventHandler() {
            @Override
            public void onRoomStreamUpdate(String roomID, ZegoUpdateType updateType, ArrayList<ZegoStream> streamList,
                JSONObject extendedData) {
                super.onRoomStreamUpdate(roomID, updateType, streamList, extendedData);

                binding.fullVideoView.onRoomStreamUpdate(roomID, updateType, streamList, extendedData);
            }

            @Override
            public void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
                super.onRemoteCameraStateUpdate(streamID, state);

                binding.fullVideoView.onRemoteCameraStateUpdate(streamID, state);
            }

            @Override
            public void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
                super.onRemoteMicStateUpdate(streamID, state);

                binding.fullVideoView.onRemoteMicStateUpdate(streamID, state);
            }

            @Override
            public void onRoomStateChanged(String roomID, ZegoRoomStateChangedReason reason, int errorCode,
                JSONObject extendedData) {
                super.onRoomStateChanged(roomID, reason, errorCode, extendedData);
                ToastUtil.show(CallingActivity.this, reason.toString());
            }

            @Override
            public void onRoomUserUpdate(String roomID, ZegoUpdateType updateType, ArrayList<ZegoUser> userList) {
                super.onRoomUserUpdate(roomID, updateType, userList);
                if(updateType == ZegoUpdateType.DELETE){
                    finish();
                }
            }
        });
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