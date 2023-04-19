package com.zegocloud.demo.cohosting.components;

import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.util.Log;
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
import com.zegocloud.demo.cohosting.internal.ZEGOInvitationService;
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

    private List<ZEGOLiveUser> adapterUserList = new ArrayList<>();

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
        ZEGOLiveUser liveUser = adapterUserList.get(position);
        Log.d(TAG, "onBindViewHolder: liveUser: " + liveUser);
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
            if (liveUser.isAudience()) {
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
                        invitationService.inviteUser(liveUser.userID, protocol.toString(),
                            new SendInvitationCallback() {
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
            }
        });
    }

    @Override
    public int getItemCount() {
        return adapterUserList.size();
    }

    public void addUserList(List<ZEGOLiveUser> userList) {
        this.adapterUserList.addAll(userList);
        sortList(this.adapterUserList);
        notifyDataSetChanged();
    }

    private void sortList(List<ZEGOLiveUser> userList) {
        List<ZEGOLiveUser> result = new ArrayList<>();
        List<ZEGOLiveUser> speaker = new ArrayList<>();
        List<ZEGOLiveUser> audience = new ArrayList<>();
        List<ZEGOLiveUser> requested = new ArrayList<>();
        List<ZEGOLiveUser> host = new ArrayList<>();
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();

        for (ZEGOLiveUser liveUser : userList) {
            boolean isYou = Objects.equals(liveUser, localUser);
            if (liveUser.isHost()) {
                host.add(liveUser);
            } else {
                if (isYou) {

                } else {
                    if (liveUser.isCoHost()) {
                        speaker.add(liveUser);
                    } else {
                        boolean isRequested = ZEGOSDKManager.getInstance().invitationService.isOtherUserInviteExisted(
                            liveUser.userID);
                        if (isRequested) {
                            requested.add(liveUser);
                        } else {
                            audience.add(liveUser);
                        }
                    }
                }
            }
        }
        Log.d(TAG, "sortList,result00: " + result);
        Log.d(TAG, "sortList,host00: " + host);
        if (localUser != null) {
            if (!host.contains(localUser)) {
                Log.d(TAG, "sortList: 111");
                if (!host.isEmpty()) {
                    result.addAll(host);
                }
                result.add(localUser);
            } else {
                Log.d(TAG, "sortList: 222");
                host.remove(localUser);
                host.add(0, localUser);
                result.addAll(host);
            }
        } else {
            result.addAll(host);
        }
        Log.d(TAG, "sortList,result11: " + result);
        result.addAll(speaker);
        result.addAll(requested);
        result.addAll(audience);

        Log.d(TAG, "sortList,host: " + host);
        Log.d(TAG, "sortList,speaker: " + speaker);
        Log.d(TAG, "sortList,requested: " + requested);
        Log.d(TAG, "sortList,audience: " + audience);
        Log.d(TAG, "sortList,result: " + result);
        userList.clear();
        userList.addAll(result);
    }

    public void removeUserList(List<ZEGOLiveUser> userList) {
        int index = this.adapterUserList.size();
        this.adapterUserList.removeAll(userList);
        notifyItemRangeRemoved(index - userList.size(), userList.size());
    }
}
