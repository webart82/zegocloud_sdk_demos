package com.zegocloud.demo.callwithinvitation.call;

import android.os.Bundle;
import android.view.Gravity;
import android.view.Window;

import androidx.appcompat.app.AppCompatActivity;

import com.zegocloud.demo.callwithinvitation.ZEGOSDKManager;
import com.zegocloud.demo.callwithinvitation.databinding.ActivityIncomingCallDialogBinding;
import com.zegocloud.demo.callwithinvitation.internal.ZIMService.InvitationListener;
import com.zegocloud.demo.callwithinvitation.utils.ToastUtil;
import com.zegocloud.demo.callwithinvitation.R;
import com.zegocloud.demo.callwithinvitation.call.internal.CallInviteInfo;

import org.json.JSONObject;

import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zim.callback.ZIMCallAcceptanceSentCallback;
import im.zego.zim.callback.ZIMCallRejectionSentCallback;
import im.zego.zim.entity.ZIMError;
import im.zego.zim.enums.ZIMErrorCode;

public class IncomingCallDialog extends AppCompatActivity {

    private ActivityIncomingCallDialogBinding binding;

    private InvitationListener listener = new InvitationListener() {
        @Override
        public void onIncomingCallInvitationTimeout(String inviter) {
            finish();
        }

        @Override
        public void onIncomingCallInvitationCancelled(String callID, String inviter, String extendedData) {
            finish();
        }

        @Override
        public void onIncomingCallInvitationAccepted(String callID, ZIMError errorInfo) {
            if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                finish();
            }
        }

        @Override
        public void onIncomingCallInvitationRejected(String callID, ZIMError errorInfo) {
            if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                finish();
            }
        }
    };
    private CallInviteInfo callInviteInfo;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);

        getWindow().setGravity(Gravity.TOP);

        binding = ActivityIncomingCallDialogBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        setFinishOnTouchOutside(false);

        ZEGOSDKManager.getInstance().addInvitationListener(listener);

        callInviteInfo = (CallInviteInfo) getIntent().getSerializableExtra("callInviteInfo");

        binding.dialogCallName.setText(callInviteInfo.callerUserName);
        if (callInviteInfo.isVideoCall()) {
            binding.dialogCallType.setText("ZEGO VIDEO CALL");
            binding.dialogCallAccept.setImageResource(R.drawable.call_icon_dialog_video_accept);
        } else {
            binding.dialogCallType.setText("ZEGO VOICE CALL");
            binding.dialogCallAccept.setImageResource(R.drawable.call_icon_dialog_voice_accept);
        }

        binding.dialogCallAccept.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance().callAccept(callInviteInfo.callID, new ZIMCallAcceptanceSentCallback() {
                @Override
                public void onCallAcceptanceSent(String callID, ZIMError errorInfo) {
                    if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                        ZEGOSDKManager.getInstance().joinExpressRoom(callID, new IZegoRoomLoginCallback() {
                            @Override
                            public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                                if (errorCode == 0) {
                                    finish();
                                    CallingActivity.startActivity(IncomingCallDialog.this, callInviteInfo);
                                } else {
                                    ToastUtil.show(IncomingCallDialog.this, "joinExpressRoom failed :" + errorCode);
                                }
                            }
                        });
                    } else {
                        ToastUtil.show(IncomingCallDialog.this, "callAccept failed :" + errorInfo.getCode());
                    }
                }
            });

        });
        binding.dialogCallDecline.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance().callReject(callInviteInfo.callID, new ZIMCallRejectionSentCallback() {
                @Override
                public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                    if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                    } else {
                        ToastUtil.show(IncomingCallDialog.this, "callReject failed :" + errorInfo.getCode());
                    }
                    finish();
                }
            });
        });

        binding.dialogReceiveCall.setOnClickListener(v -> {
            CallWaitingActivity.startActivity(IncomingCallDialog.this, callInviteInfo);
        });
    }

    @Override
    public void onBackPressed() {
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ZEGOSDKManager.getInstance().removeInvitationListener(listener);
    }
}