package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.ForegroundColorSpan;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.RecyclerView.ViewHolder;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.Utils;
import im.zego.zegoexpress.entity.ZegoBarrageMessageInfo;
import java.util.ArrayList;
import java.util.List;

public class BarrageMessageAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private List<ZegoBarrageMessageInfo> barrageMessageInfoList = new ArrayList<>();

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = null;
        view = LayoutInflater.from(parent.getContext()).inflate(R.layout.zego_uikit_item_inroom_message, parent, false);
        return new ViewHolder(view) {
        };
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        ZegoBarrageMessageInfo message = barrageMessageInfoList.get(position);
        ZEGOLiveUser liveUser = ZEGOSDKManager.getInstance().rtcService.getUser(message.fromUser.userID);
        Context context = holder.itemView.getContext();
        DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();

        String hostTag = "Host";
        StringBuilder builder = new StringBuilder();
        if (liveUser.isHost()) {
            builder.append(hostTag);
            builder.append(" ");
        }
        builder.append(liveUser.userName);
        builder.append(" ");
        builder.append(message.message);
        String source = builder.toString();
        SpannableString string = new SpannableString(source);
        RoundBackgroundColorSpan backgroundColorSpan = new RoundBackgroundColorSpan(context,
            ContextCompat.getColor(context, R.color.purple_dark),
            ContextCompat.getColor(context, android.R.color.white));
        if (liveUser.isHost()) {
            AbsoluteSizeSpan absoluteSizeSpan = new AbsoluteSizeSpan(Utils.sp2px(10, displayMetrics));
            string.setSpan(absoluteSizeSpan, 0, hostTag.length(),
                Spannable.SPAN_INCLUSIVE_EXCLUSIVE);
            string.setSpan(backgroundColorSpan, 0, hostTag.length(),
                Spannable.SPAN_INCLUSIVE_EXCLUSIVE);
        }
        ForegroundColorSpan foregroundColorSpan = new ForegroundColorSpan(
            ContextCompat.getColor(context, R.color.teal));
        int indexOfUser = source.indexOf(liveUser.userName);
        string.setSpan(foregroundColorSpan, indexOfUser, indexOfUser + liveUser.userName.length(),
            Spannable.SPAN_INCLUSIVE_EXCLUSIVE);
        AbsoluteSizeSpan absoluteSizeSpan = new AbsoluteSizeSpan(Utils.sp2px(13, displayMetrics));
        string.setSpan(absoluteSizeSpan, indexOfUser, indexOfUser + liveUser.userName.length(),
            Spannable.SPAN_INCLUSIVE_EXCLUSIVE);

        TextView textView = holder.itemView.findViewById(R.id.tv_inroom_message);
        textView.setText(string);
    }

    @Override
    public int getItemCount() {
        return barrageMessageInfoList.size();
    }

    public void addMessages(ArrayList<ZegoBarrageMessageInfo> messageList) {
        int size = this.barrageMessageInfoList.size();
        this.barrageMessageInfoList.addAll(messageList);
        notifyItemRangeInserted(size, messageList.size());
    }

    public void addMessage(ZegoBarrageMessageInfo message) {
        int size = this.barrageMessageInfoList.size();
        this.barrageMessageInfoList.add(message);
        notifyItemInserted(size);
    }
}
