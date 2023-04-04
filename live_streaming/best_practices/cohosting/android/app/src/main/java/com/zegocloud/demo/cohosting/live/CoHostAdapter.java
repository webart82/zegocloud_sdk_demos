package com.zegocloud.demo.cohosting.live;

import android.graphics.Color;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.RecyclerView.ViewHolder;
import com.google.android.material.card.MaterialCardView;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.components.ZEGOVideoView;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import java.util.ArrayList;
import java.util.List;

public class CoHostAdapter extends RecyclerView.Adapter<ViewHolder> {

    private List<String> userIDList = new ArrayList<>();

    private static final String TAG = "CoHostAdapter";

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        MaterialCardView cardView = new MaterialCardView(parent.getContext());
        DisplayMetrics displayMetrics = parent.getContext().getResources().getDisplayMetrics();
        cardView.setRadius(dp2px(8f, displayMetrics));
        cardView.setCardBackgroundColor(Color.GREEN);

        MaterialCardView.LayoutParams params = new MaterialCardView.LayoutParams(dp2px(93, displayMetrics),
            dp2px(124, displayMetrics));
        cardView.addView(new ZEGOVideoView(parent.getContext()), params);
        return new ViewHolder(cardView) {
        };
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        String userID = userIDList.get(position);
        ZEGOLiveUser userInfo = ZEGOSDKManager.getInstance().rtcService.getUserInfo(userID);
        ZEGOVideoView videoView = (ZEGOVideoView) ((MaterialCardView) holder.itemView).getChildAt(0);
        videoView.setUserID(userID);
    }

    @Override
    public int getItemCount() {
        return userIDList.size();
    }

    public void addUserIDList(List<String> list) {
        int position = userIDList.size();
        userIDList.addAll(list);
        notifyItemRangeInserted(position, userIDList.size());
        Log.d(TAG, "addUserIDList() after with: userIDList = [" + this.userIDList + "]");
    }

    public static int dp2px(float v, DisplayMetrics displayMetrics) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, displayMetrics);
    }

    public static int sp2px(float v, DisplayMetrics displayMetrics) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, displayMetrics);
    }
}
