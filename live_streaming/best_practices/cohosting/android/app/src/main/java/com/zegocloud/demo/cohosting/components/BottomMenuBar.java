package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Gravity;
import android.widget.LinearLayout;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.Utils;
import java.util.List;

public class BottomMenuBar extends LinearLayout {

    private MemberListButton memberListButton;
    private MemberListView memberListView;
    private CoHostButton coHostButton;

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

        memberListButton = new MemberListButton(getContext());
        memberListButton.setOnClickListener(v -> {
            if (memberListView == null) {
                memberListView = new MemberListView(getContext());
            }
            memberListView.show();
        });
        addView(memberListButton, generateChildImageLayoutParams());

        coHostButton = new CoHostButton(getContext());
        addView(coHostButton, generateChildTextLayoutParams());
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

    public void onUserJoinRoom() {
        coHostButton.onUserJoinRoom();
        checkCoHostButton();
    }

    private static final String TAG = "BottomMenuBar";

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

    public void checkCoHostButton() {
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        Log.d(TAG, "checkCoHostButton() called :" + localUser);
        if (localUser.isAudience()) {
            coHostButton.setVisibility(VISIBLE);
        } else {
            coHostButton.setVisibility(GONE);
        }
    }
}
