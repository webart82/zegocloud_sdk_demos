package com.zegocloud.demo.cohosting.components;

import android.util.DisplayMetrics;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.RecyclerView.ViewHolder;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.components.ZEGOVideoView;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.Utils;
import java.util.ArrayList;
import java.util.List;

public class CoHostAdapter extends RecyclerView.Adapter<ViewHolder> {

    private List<String> userIDList = new ArrayList<>();

    private static final String TAG = "CoHostAdapter";

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.layout_cohost_video, parent, false);

        DisplayMetrics displayMetrics = parent.getContext().getResources().getDisplayMetrics();
        ViewGroup.LayoutParams params = new ViewGroup.LayoutParams(Utils.dp2px(93, displayMetrics),
            Utils.dp2px(124, displayMetrics));
        view.setLayoutParams(params);
        return new ViewHolder(view) {
        };
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        String userID = userIDList.get(position);
        ZEGOLiveUser liveUser = ZEGOSDKManager.getInstance().rtcService.getUser(userID);
        ZEGOVideoView videoView = holder.itemView.findViewById(R.id.cohost_video_view);
        TextView textView = holder.itemView.findViewById(R.id.cohost_video_name);
        videoView.setUserID(userID);
        videoView.setVisibility(liveUser.isCameraOpen() ? View.VISIBLE : View.GONE);
        textView.setText(liveUser.userName);
    }

    @Override
    public int getItemCount() {
        return userIDList.size();
    }

    public void addUserIDList(List<String> list) {
        userIDList.addAll(list);
        notifyDataSetChanged();
        Log.d(TAG, "addUserIDList() after with: userIDList = [" + this.userIDList + "]");
    }

    public void removeUserIDList(List<String> list) {
        Log.d(TAG, "removeUserIDList() after with: list = [" + list + "]");
        userIDList.removeAll(list);
        notifyDataSetChanged();
        Log.d(TAG, "removeUserIDList() after with: userIDList = [" + this.userIDList + "]");
    }
}
