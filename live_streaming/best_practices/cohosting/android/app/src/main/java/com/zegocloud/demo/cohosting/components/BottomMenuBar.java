package com.zegocloud.demo.cohosting.components;

import android.app.Activity;
import android.content.Context;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.widget.ImageView;
import android.widget.ImageView.ScaleType;
import android.widget.LinearLayout;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.CameraListener;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.MicrophoneListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.Utils;
import java.util.List;

public class BottomMenuBar extends LinearLayout {

    private MemberListButton memberListButton;
    private MemberListView memberListView;
    private CoHostButton coHostButton;
    private LinearLayout childLinearLayout;
    private ToggleCameraButton cameraButton;
    private ToggleMicrophoneButton microphoneButton;
    private SwitchCameraButton switchCameraButton;

    public BottomMenuBar(Context context) {
        super(context);
        initView();
    }

    public BottomMenuBar(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public BottomMenuBar(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    public BottomMenuBar(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView();
    }

    private void initView() {
        setOrientation(LinearLayout.HORIZONTAL);
        setLayoutParams(new LayoutParams(-1, -2));
        setGravity(Gravity.END);

        ImageView messageButton = new ImageView(getContext());
        messageButton.setImageResource(R.drawable.audioroom_icon_im);
        messageButton.setScaleType(ScaleType.FIT_XY);
        LinearLayout.LayoutParams btnParam = new LayoutParams(-2, -2);
        DisplayMetrics displayMetrics = getResources().getDisplayMetrics();
        int marginStart = Utils.dp2px(16, displayMetrics);
        int marginTop = Utils.dp2px(10, displayMetrics);
        btnParam.setMargins(marginStart, marginTop, 0, marginStart);
        addView(messageButton, btnParam);
        messageButton.setOnClickListener(v -> {
            if (getContext() instanceof Activity) {
                BottomInputDialog bottomInputDialog = new BottomInputDialog(getContext());
                bottomInputDialog.show();
            }
        });

        childLinearLayout = new LinearLayout(getContext());
        childLinearLayout.setOrientation(LinearLayout.HORIZONTAL);
        childLinearLayout.setGravity(Gravity.END);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, -2, 1);
        addView(childLinearLayout, params);
        int paddingEnd = Utils.dp2px(8, getResources().getDisplayMetrics());
        childLinearLayout.setPadding(0, 0, paddingEnd, 0);

        memberListButton = new MemberListButton(getContext());
        memberListButton.setOnClickListener(v -> {
            if (memberListView == null) {
                memberListView = new MemberListView(getContext());
            }
            memberListView.show();
        });
        childLinearLayout.addView(memberListButton, generateChildImageLayoutParams());

        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        cameraButton = new ToggleCameraButton(getContext());
        cameraButton.updateState(localUser.isCameraOpen());
        childLinearLayout.addView(cameraButton, generateChildImageLayoutParams());
        ZEGOSDKManager.getInstance().rtcService.addCameraListener(new CameraListener() {
            @Override
            public void onCameraOpen(String userID, boolean open) {
                if (userID.equals(localUser.userID)) {
                    cameraButton.updateState(open);
                }
            }
        });

        microphoneButton = new ToggleMicrophoneButton(getContext());
        microphoneButton.updateState(localUser.isMicrophoneOpen());
        childLinearLayout.addView(microphoneButton, generateChildImageLayoutParams());
        ZEGOSDKManager.getInstance().rtcService.addMicrophoneListener(new MicrophoneListener() {
            @Override
            public void onMicrophoneOpen(String userID, boolean open) {
                ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
                if (userID.equals(localUser.userID)) {
                    microphoneButton.updateState(open);
                }
            }
        });

        switchCameraButton = new SwitchCameraButton(getContext());
        childLinearLayout.addView(switchCameraButton, generateChildImageLayoutParams());

        coHostButton = new CoHostButton(getContext());
        ZEGOInvitation invitation = new ZEGOInvitation();
        coHostButton.setInvitation(invitation);
        childLinearLayout.addView(coHostButton, generateChildTextLayoutParams());

    }

    private LayoutParams generateChildImageLayoutParams() {
        int size = Utils.dp2px(36f, getResources().getDisplayMetrics());
        int marginTop = Utils.dp2px(10f, getResources().getDisplayMetrics());
        int marginBottom = Utils.dp2px(16f, getResources().getDisplayMetrics());
        int marginEnd = Utils.dp2px(8, getResources().getDisplayMetrics());
        LayoutParams layoutParams = new LayoutParams(size, size);
        layoutParams.topMargin = marginTop;
        layoutParams.bottomMargin = marginBottom;
        layoutParams.rightMargin = marginEnd;
        return layoutParams;
    }

    private LayoutParams generateChildTextLayoutParams() {
        int size = Utils.dp2px(36f, getResources().getDisplayMetrics());
        int marginTop = Utils.dp2px(10f, getResources().getDisplayMetrics());
        int marginBottom = Utils.dp2px(16f, getResources().getDisplayMetrics());
        int marginEnd = Utils.dp2px(8, getResources().getDisplayMetrics());
        LayoutParams layoutParams = new LayoutParams(LayoutParams.WRAP_CONTENT, size);
        layoutParams.topMargin = marginTop;
        layoutParams.bottomMargin = marginBottom;
        layoutParams.rightMargin = marginEnd;
        return layoutParams;
    }

    public void checkRedPoint() {
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        if (localUser.isHost()) {
            List<ZEGOLiveUser> otherUserInviteList = ZEGOSDKManager.getInstance().invitationService.getOtherUserInviteList();
            if (!otherUserInviteList.isEmpty()) {
                memberListButton.showRedPoint();
            } else {
                memberListButton.hideRedPoint();
            }
        }

        updateList();
    }

    public void updateList() {
        if (memberListView != null) {
            memberListView.updateList();
        }
    }

    private static final String TAG = "BottomMenuBar";

    public void checkBottomsButtons() {
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        Log.d(TAG, "checkBottomsButtons: " + localUser);
        if (localUser.isAudience() || localUser.isCoHost()) {
            coHostButton.setVisibility(VISIBLE);
        } else {
            coHostButton.setVisibility(GONE);
        }
        coHostButton.updateUI();

        if (localUser.isAudience()) {
            cameraButton.setVisibility(GONE);
            microphoneButton.setVisibility(GONE);
            switchCameraButton.setVisibility(GONE);
        } else {
            cameraButton.setVisibility(VISIBLE);
            microphoneButton.setVisibility(VISIBLE);
            switchCameraButton.setVisibility(VISIBLE);
        }
    }
}
