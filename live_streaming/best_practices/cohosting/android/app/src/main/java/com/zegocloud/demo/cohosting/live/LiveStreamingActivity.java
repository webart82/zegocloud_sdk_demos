package com.zegocloud.demo.cohosting.live;

import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AlertDialog.Builder;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.databinding.ActivityLiveStreamingBinding;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.CameraListener;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.MicrophoneListener;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.RoomStreamChangeListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.IncomingInvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.OutgoingInvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveRole;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import org.json.JSONObject;

public class LiveStreamingActivity extends AppCompatActivity {

    private ActivityLiveStreamingBinding binding;
    private static final String TAG = "LiveStreamingActivity";
    private String liveID;
    private CoHostAdapter coHostAdapter;
    private AlertDialog inviteCoHostDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityLiveStreamingBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        boolean isHost = getIntent().getBooleanExtra("host", true);
        liveID = getIntent().getStringExtra("liveID");

        ZEGOLiveUser userInfo = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        userInfo.setRole(isHost ? ZEGOLiveRole.HOST : ZEGOLiveRole.AUDIENCE);

        binding.previewStart.setOnClickListener(v -> {
            joinRoom();
        });

        if (userInfo.isHost()) {
            // join when click start
            ZEGOSDKManager.getInstance().rtcService.enableCamera(true);
            ZEGOSDKManager.getInstance().rtcService.openMicrophone(true);
            binding.previewStart.setVisibility(View.VISIBLE);
            binding.mainFullVideo.startPreviewOnly();

        } else {
            // join right now
            ZEGOSDKManager.getInstance().rtcService.enableCamera(false);
            ZEGOSDKManager.getInstance().rtcService.openMicrophone(false);
            binding.previewStart.setVisibility(View.GONE);
            joinRoom();
        }
        binding.liveBottomMenuBar.setVisibility(View.GONE);
        listenRTCEvent();
    }

    private void joinRoom() {
        ZEGOSDKManager.getInstance().joinRTCRoom(liveID, new IZegoRoomLoginCallback() {
            @Override
            public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                if (errorCode != 0) {
                    onJoinRoomFailed();
                } else {
                    onJoinRoomSuccess();
                }
            }
        });
    }

    private void onJoinRoomFailed() {
        finish();
    }

    private void onJoinRoomSuccess() {
        binding.previewStart.setVisibility(View.GONE);
        ZEGOLiveUser localUserInfo = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        if (localUserInfo.isHost()) {
            binding.mainFullVideo.setUserID(localUserInfo.userID);
        }
        coHostAdapter = new CoHostAdapter();
        binding.mainSmallViewParent.setLayoutManager(new LinearLayoutManager(this));
        binding.mainSmallViewParent.setAdapter(coHostAdapter);

        binding.liveBottomMenuBar.setVisibility(View.VISIBLE);
        binding.liveBottomMenuBar.checkBottomsButtons();

        addUserVideos();
    }

    private void addUserVideos() {
        List<ZEGOLiveUser> videoUserList = ZEGOSDKManager.getInstance().rtcService.getVideoUserList();
        List<String> coHostUserIDList = new ArrayList<>();
        for (ZEGOLiveUser liveUser : videoUserList) {
            if (liveUser.isHost()) {
                binding.mainFullVideo.setUserID(liveUser.userID);
            } else {
                coHostUserIDList.add(liveUser.userID);
            }
        }
        if (!coHostUserIDList.isEmpty()) {
            coHostAdapter.addUserIDList(coHostUserIDList);
        }
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (isFinishing()) {
            ZEGOSDKManager.getInstance().leaveRTCRoom();
            ZEGOSDKManager.getInstance().rtcService.clear();
        }
    }

    public void listenRTCEvent() {
        ZEGOSDKManager.getInstance().rtcService.addCameraListener(new CameraListener() {
            @Override
            public void onCameraOpen(String userID, boolean open) {
                ZEGOLiveUser hostUser = ZEGOSDKManager.getInstance().rtcService.getHostUser();
                if (hostUser != null && Objects.equals(hostUser.userID, userID)) {
                    if (open) {
                        binding.mainFullVideo.setVisibility(View.VISIBLE);
                    } else {
                        binding.mainFullVideo.setVisibility(View.GONE);
                    }
                } else {
                    coHostAdapter.notifyDataSetChanged();
                }
                Log.d(TAG, "onCameraOpen() called with: userID = [" + userID + "], open = [" + open + "]");
            }
        });
        ZEGOSDKManager.getInstance().rtcService.addMicrophoneListener(new MicrophoneListener() {
            @Override
            public void onMicrophoneOpen(String userID, boolean open) {
                Log.d(TAG, "onMicrophoneOpen() called with: userID = [" + userID + "], open = [" + open + "]");
            }
        });
        ZEGOSDKManager.getInstance().rtcService.addStreamChangeListener(new RoomStreamChangeListener() {
            @Override
            public void onStreamAdd(List<ZEGOLiveUser> userList) {
                Log.d(TAG, "onStreamAdd() called with: userList = [" + userList + "]");
                List<String> coHostUserIDList = new ArrayList<>();
                for (ZEGOLiveUser liveUser : userList) {
                    if (liveUser.isHost()) {
                        binding.mainFullVideo.setUserID(liveUser.userID);
                        binding.mainFullVideo.setVisibility(View.VISIBLE);
                    } else {
                        coHostUserIDList.add(liveUser.userID);
                    }
                }
                if (!coHostUserIDList.isEmpty()) {
                    coHostAdapter.addUserIDList(coHostUserIDList);
                }

                binding.liveBottomMenuBar.updateList();
                binding.liveBottomMenuBar.checkBottomsButtons();
            }

            @Override
            public void onStreamRemove(List<ZEGOLiveUser> userList) {
                Log.d(TAG, "onStreamRemove() called with: userList = [" + userList + "]");
                List<String> coHostUserIDList = new ArrayList<>();
                for (ZEGOLiveUser liveUser : userList) {
                    if (Objects.equals(binding.mainFullVideo.getUserID(), liveUser.userID)) {
                        binding.mainFullVideo.setUserID("");
                        binding.mainFullVideo.setVisibility(View.GONE);
                    } else {
                        coHostUserIDList.add(liveUser.userID);
                    }
                }
                coHostAdapter.removeUserIDList(coHostUserIDList);
                binding.liveBottomMenuBar.updateList();
                binding.liveBottomMenuBar.checkBottomsButtons();
            }
        });
        ZEGOSDKManager.getInstance().invitationService.addOutgoingInvitationListener(new OutgoingInvitationListener() {
            @Override
            public void onActionSendInvitation(int errorCode, String invitationID, String extendedData,
                List<String> errorInvitees) {

            }

            @Override
            public void onActionCancelInvitation(int errorCode, String invitationID, List<String> errorInvitees) {

            }

            @Override
            public void onSendInvitationButReceiveResponseTimeout(String invitationID, List<String> invitees) {

            }

            @Override
            public void onSendInvitationAndIsAccepted(String invitationID, String invitee, String extendedData) {
                ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
                ZEGOLiveUser localUser = rtcService.getLocalUser();
                if (localUser.isAudience()) {
                    rtcService.openMicrophone(true);
                    rtcService.enableCamera(true);
                    rtcService.startPublishLocalAudioVideo();
                }
            }

            @Override
            public void onSendInvitationButIsRejected(String invitationID, String invitee, String extendedData) {

            }
        });

        ZEGOSDKManager.getInstance().invitationService.addIncomingInvitationListener(new IncomingInvitationListener() {
            @Override
            public void onReceiveNewInvitation(String invitationID, String userID, String extendedData) {
                ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
                if (localUser.isAudience()) {
                    if (inviteCoHostDialog == null) {
                        AlertDialog.Builder builder = new Builder(LiveStreamingActivity.this);
                        builder.setTitle("you received a new invitation");
                        ZEGOInvitation zegoInvitation = ZEGOSDKManager.getInstance().invitationService.getZEGOInvitation(
                            invitationID);

                        if (zegoInvitation != null) {
                            ZEGOLiveUser inviter = ZEGOSDKManager.getInstance().rtcService.getUser(
                                zegoInvitation.inviter);
                            if (inviter != null) {
                                builder.setMessage(inviter.userName + " invite you to CoHost");
                            }
                        }
                        builder.setPositiveButton(R.string.ok, new OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
                                rtcService.openMicrophone(true);
                                rtcService.enableCamera(true);
                                rtcService.startPublishLocalAudioVideo();
                                dialog.dismiss();
                            }
                        });
                        builder.setNegativeButton(R.string.cancel, new OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                dialog.dismiss();
                            }
                        });
                        inviteCoHostDialog = builder.create();
                    }
                    if (!inviteCoHostDialog.isShowing()) {
                        inviteCoHostDialog.show();
                    }
                } else if (localUser.isHost()) {
                    binding.liveBottomMenuBar.checkRedPoint();
                }
            }

            @Override
            public void onReceiveInvitationButResponseTimeout(String invitationID) {
                binding.liveBottomMenuBar.checkRedPoint();
            }

            @Override
            public void onReceiveInvitationButIsCancelled(String invitationID, String inviter, String extendedData) {
                if (inviteCoHostDialog != null && inviteCoHostDialog.isShowing()) {
                    inviteCoHostDialog.dismiss();
                }
                binding.liveBottomMenuBar.checkRedPoint();
            }

            @Override
            public void onActionAcceptInvitation(int errorCode, String invitationID) {
                binding.liveBottomMenuBar.checkRedPoint();
            }

            @Override
            public void onActionRejectInvitation(int errorCode, String invitationID) {
                binding.liveBottomMenuBar.checkRedPoint();
            }
        });
    }
}