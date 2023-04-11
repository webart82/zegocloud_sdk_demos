package com.zegocloud.demo.cohosting.components;

import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AlertDialog.Builder;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.RecyclerView.ViewHolder;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.invitation.ZEGOInvitationService;
import com.zegocloud.demo.cohosting.internal.invitation.common.AcceptInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.RejectInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.SendInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.invitation.impl.CoHostProtocol;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.ToastUtil;
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

    private static final String TAG = "MemberListAdapter";

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

        ZEGOInvitationService invitationService = ZEGOSDKManager.getInstance().invitationService;
        boolean userCoHostRequestExisted = invitationService.isOtherUserInviteExisted(liveUser.userID);
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
            ZEGOInvitation userInvitation = invitationService.getUserInvitation(liveUser.userID);
            if (userInvitation != null) {
                invitationService.acceptInvite(userInvitation, new AcceptInvitationCallback() {
                    @Override
                    public void onResult(int errorCode, String invitationID) {
                    }
                });
            } else {
                ToastUtil.show(holder.itemView.getContext(), "userInvitation not existed");
            }
        });
        disagree.setOnClickListener(v -> {
            ZEGOInvitation userInvitation = invitationService.getUserInvitation(liveUser.userID);
            if (userInvitation != null) {
                invitationService.rejectInvite(userInvitation, new RejectInvitationCallback() {
                    @Override
                    public void onResult(int errorCode, String invitationID) {

                    }
                });
            } else {
                ToastUtil.show(holder.itemView.getContext(), "userInvitation not existed");
            }
        });
        more.setOnClickListener(v -> {
            AlertDialog.Builder alertBuilder = new Builder(more.getContext());
            alertBuilder.setTitle("Invite CoHost");
            alertBuilder.setMessage("Are you sure to invite " + liveUser.userName + " to CoHost?");
            alertBuilder.setPositiveButton(R.string.ok, new OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    CoHostProtocol protocol = new CoHostProtocol();
                    protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                    protocol.setTargetID(liveUser.userID);
                    protocol.setOperatorID(localUser.userID);
                    invitationService.inviteUser(liveUser.userID, protocol.toString(), new SendInvitationCallback() {
                        @Override
                        public void onResult(int errorCode, String invitationID, List<String> errorInvitees) {

                        }
                    });
                    dialog.dismiss();
                }
            });
            alertBuilder.setNegativeButton(R.string.cancel, new OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    dialog.dismiss();
                }
            });
            AlertDialog alertDialog = alertBuilder.create();
            alertDialog.show();
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
