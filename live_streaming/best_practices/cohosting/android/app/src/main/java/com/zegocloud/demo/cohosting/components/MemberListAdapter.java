package com.zegocloud.demo.cohosting.components;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.RecyclerView.ViewHolder;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.Utils;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class MemberListAdapter extends RecyclerView.Adapter<ViewHolder> {

    private List<ZEGOLiveUser> userList = new ArrayList<>();

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.layout_item_member, parent, false);
        int height = Utils.dp2px(70, parent.getContext().getResources().getDisplayMetrics());
        view.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, height));
        return new ViewHolder(view) {
        };
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        ZEGOLiveUser liveUser = userList.get(position);
        ImageView customAvatar = holder.itemView.findViewById(R.id.live_member_item_custom);
        TextView memberName = holder.itemView.findViewById(R.id.live_member_item_name);
        TextView tag = holder.itemView.findViewById(R.id.live_member_item_tag);
        TextView agree = holder.itemView.findViewById(R.id.live_member_item_agree);
        TextView disagree = holder.itemView.findViewById(R.id.live_member_item_disagree);
        TextView more = holder.itemView.findViewById(R.id.live_member_item_more);
        memberName.setText(liveUser.userName);

        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();

        boolean isYou = Objects.equals(localUser, liveUser);
        StringBuilder builder = new StringBuilder();
        if (isYou || liveUser.isHost() || liveUser.isCoHost()) {
            builder.append("(");
        }
        if (isYou) {
            builder.append(holder.itemView.getContext().getString(R.string.liveaudioroom_you));
        }
        if (liveUser.isHost()) {
            if (isYou) {
                builder.append(",");
            }
            builder.append(holder.itemView.getContext().getString(R.string.liveaudioroom_host));
        } else {
            if (liveUser.isCoHost()) {
                if (isYou) {
                    builder.append(",");
                }
                builder.append(holder.itemView.getContext().getString(R.string.liveaudioroom_speaker));
            }
        }

        if (isYou || liveUser.isHost() || liveUser.isCoHost()) {
            builder.append(")");
        }
        tag.setText(builder.toString());

        boolean userCoHostRequestExisted = ZEGOSDKManager.getInstance().imService.isUserInviteExisted(liveUser.userID);
        if (isYou) {
            agree.setVisibility(View.GONE);
            disagree.setVisibility(View.GONE);
            more.setVisibility(View.GONE);
        } else {
            if (localUser.isHost()) {
                if (liveUser.isHost()) {
                    agree.setVisibility(View.GONE);
                    disagree.setVisibility(View.GONE);
                    more.setVisibility(View.GONE);
                } else {
                    if (userCoHostRequestExisted) {
                        agree.setVisibility(View.VISIBLE);
                        disagree.setVisibility(View.VISIBLE);
                        more.setVisibility(View.GONE);
                    } else {
                        agree.setVisibility(View.GONE);
                        disagree.setVisibility(View.GONE);
                        more.setVisibility(View.VISIBLE);
                    }
                }
            } else {
                agree.setVisibility(View.GONE);
                disagree.setVisibility(View.GONE);
                more.setVisibility(View.GONE);
            }
        }

        agree.setOnClickListener(v -> {
            //            invitationService.acceptInvitation(uiKitUser, null);
            //            dismiss();
        });
        disagree.setOnClickListener(v -> {
            //            invitationService.refuseInvitation(uiKitUser, null);
            //            dismiss();
        });
        more.setOnClickListener(v -> {
            //            if (memberListConfig != null && memberListConfig.memberListMoreButtonPressedListener != null) {
            //                memberListConfig.memberListMoreButtonPressedListener.onMemberListMoreButtonPressed((ViewGroup) view,
            //                    uiKitUser);
            //            } else {
            //                if (seatLocked) {
            //                    if (!isUserSpeaker) {
            //                        showMoreOperationDialog(uiKitUser);
            //                        dismiss();
            //                    }
            //                }
            //            }
        });
    }

    @Override
    public int getItemCount() {
        return userList.size();
    }

    public void addUserList(List<ZEGOLiveUser> userList) {
        if (this.userList.isEmpty()) {
            this.userList.addAll(userList);
            notifyDataSetChanged();
        } else {
            int index = this.userList.size();
            this.userList.addAll(userList);
            notifyItemRangeInserted(index, userList.size());
        }

    }

    public void removeUserList(List<ZEGOLiveUser> userList) {
        int index = this.userList.size();
        this.userList.removeAll(userList);
        notifyItemRangeRemoved(index - userList.size(), userList.size());
    }
}
