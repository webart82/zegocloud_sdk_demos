package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.Window;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.databinding.LayoutMemberlistBinding;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService.RoomUserChangeListener;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import java.util.List;

public class MemberListView extends BottomSheetDialog {

    private LayoutMemberlistBinding binding;
    private MemberListAdapter memberListAdapter;

    public MemberListView(@NonNull Context context) {
        super(context, R.style.TransparentDialog);
    }

    public MemberListView(@NonNull Context context, int theme) {
        super(context, theme);
    }

    protected MemberListView(@NonNull Context context, boolean cancelable, OnCancelListener cancelListener) {
        super(context, cancelable, cancelListener);
    }

    private static final String TAG = "MemberListView";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = LayoutMemberlistBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        Window window = getWindow();
        WindowManager.LayoutParams lp = window.getAttributes();
        lp.width = WindowManager.LayoutParams.MATCH_PARENT;
        lp.height = WindowManager.LayoutParams.WRAP_CONTENT;
        lp.dimAmount = 0.1f;
        lp.gravity = Gravity.BOTTOM;
        window.setAttributes(lp);
        setCanceledOnTouchOutside(true);
        window.setBackgroundDrawable(new ColorDrawable());

        // both need setPeekHeight & setLayoutParams
        DisplayMetrics displayMetrics = getContext().getResources().getDisplayMetrics();
        int height = (int) (displayMetrics.heightPixels * 0.6f);
        getBehavior().setPeekHeight(height);
        CoordinatorLayout.LayoutParams params = new CoordinatorLayout.LayoutParams(-1, height);
        binding.liveMemberListLayout.setLayoutParams(params);

        Log.d(TAG, "onCreate() called with: savedInstanceState = [" + savedInstanceState + "]");

        memberListAdapter = new MemberListAdapter();
        memberListAdapter.addUserList(ZEGOSDKManager.getInstance().rtcService.getUserList());
        binding.memberRecyclerview.setAdapter(memberListAdapter);
        binding.memberRecyclerview.setLayoutManager(new LinearLayoutManager(getContext()));

        binding.liveMemberListCount.setText(String.valueOf(memberListAdapter.getItemCount()));
        ZEGOSDKManager.getInstance().rtcService.addUserChangeListener(new RoomUserChangeListener() {
            @Override
            public void onUserEnter(List<ZEGOLiveUser> userList) {
                memberListAdapter.addUserList(userList);
                binding.liveMemberListCount.setText(String.valueOf(memberListAdapter.getItemCount()));
            }

            @Override
            public void onUserLeft(List<ZEGOLiveUser> userList) {
                memberListAdapter.removeUserList(userList);
                binding.liveMemberListCount.setText(String.valueOf(memberListAdapter.getItemCount()));
            }
        });
    }

    public void updateList() {
        if (memberListAdapter != null) {
            memberListAdapter.notifyDataSetChanged();
        }
    }
}
