package com.zegocloud.demo.cohosting.live;

import android.os.Bundle;
import android.view.View;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.databinding.ActivityLiveStreamingBinding;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveRole;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import im.zego.zegoexpress.callback.IZegoEventHandler;
import im.zego.zegoexpress.callback.IZegoRoomLoginCallback;
import im.zego.zegoexpress.constants.ZegoRemoteDeviceState;
import im.zego.zegoexpress.constants.ZegoUpdateType;
import im.zego.zegoexpress.entity.ZegoStream;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONObject;

public class LiveStreamingActivity extends AppCompatActivity {

    private ActivityLiveStreamingBinding binding;
    private static final String TAG = "LiveStreamingActivity";
    private String liveID;
    private CoHostAdapter coHostAdapter;
    private String hostUserID;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityLiveStreamingBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        boolean isHost = getIntent().getBooleanExtra("host", true);
        liveID = getIntent().getStringExtra("liveID");

        ZEGOLiveUser userInfo = ZEGOSDKManager.getInstance().rtcService.getLocalUserInfo();
        userInfo.setRole(isHost ? ZEGOLiveRole.HOST : ZEGOLiveRole.AUDIENCE);

        binding.previewStart.setOnClickListener(v -> {
            joinRoom();
        });

        if (userInfo.isHost()) {
            // join when click start
            ZEGOSDKManager.getInstance().rtcService.enableCamera(true);
            binding.previewStart.setVisibility(View.VISIBLE);
            binding.mainFullVideo.startPreviewOnly();
        } else {
            // join right now
            ZEGOSDKManager.getInstance().rtcService.enableCamera(false);
            binding.previewStart.setVisibility(View.GONE);
            joinRoom();
        }
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
        ZEGOSDKManager.getInstance().rtcService.enableCamera(false);
        finish();
    }

    private void onJoinRoomSuccess() {
        binding.previewStart.setVisibility(View.GONE);
        ZEGOLiveUser localUserInfo = ZEGOSDKManager.getInstance().rtcService.getLocalUserInfo();
        if (localUserInfo.isHost()) {
            binding.mainFullVideo.setUserID(localUserInfo.userID);
        }
        coHostAdapter = new CoHostAdapter();
        binding.mainSmallViewParent.setLayoutManager(new LinearLayoutManager(this));
        binding.mainSmallViewParent.setAdapter(coHostAdapter);

        addUserVideos(ZEGOSDKManager.getInstance().rtcService.getVideoUserIDList());
    }

    private void addUserVideos(List<String> videoUserIDList) {
        hostUserID = null;
        List<String> coHostUserIDList = new ArrayList<>();
        for (String userID : videoUserIDList) {
            ZEGOLiveUser userInfo = ZEGOSDKManager.getInstance().rtcService.getUserInfo(userID);
            if (userInfo != null) {
                if (userInfo.isHost()) {
                    hostUserID = userInfo.userID;
                } else {
                    coHostUserIDList.add(userInfo.userID);
                }
            }
        }
        if (hostUserID != null) {
            binding.mainFullVideo.setUserID(hostUserID);
        }
        coHostAdapter.addUserIDList(coHostUserIDList);
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (isFinishing()) {
            ZEGOSDKManager.getInstance().leaveRTCRoom();
        }
    }

    public void listenRTCEvent() {
        ZEGOSDKManager.getInstance().rtcService.setEventHandler(new IZegoEventHandler() {
            @Override
            public void onRoomStreamUpdate(String roomID, ZegoUpdateType updateType, ArrayList<ZegoStream> streamList,
                JSONObject extendedData) {
                super.onRoomStreamUpdate(roomID, updateType, streamList, extendedData);

                List<String> coHostUserIDList = new ArrayList<>();
                for (ZegoStream zegoStream : streamList) {
                    if (zegoStream.streamID.endsWith("_host")) {
                        hostUserID = zegoStream.user.userID;
                    } else {
                        coHostUserIDList.add(zegoStream.user.userID);
                    }
                }
                if (hostUserID != null) {
                    binding.mainFullVideo.setUserID(hostUserID);
                }
                coHostAdapter.addUserIDList(coHostUserIDList);
            }

            @Override
            public void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
                super.onRemoteCameraStateUpdate(streamID, state);

            }

            @Override
            public void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
                super.onRemoteMicStateUpdate(streamID, state);

            }
        });
    }
}