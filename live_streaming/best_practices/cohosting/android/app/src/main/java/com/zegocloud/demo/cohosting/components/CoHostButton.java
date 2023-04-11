package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.graphics.Color;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.invitation.ZEGOInvitationService;
import com.zegocloud.demo.cohosting.internal.invitation.common.AcceptInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.CancelInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.OutgoingInvitationListener;
import com.zegocloud.demo.cohosting.internal.invitation.common.RejectInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.SendInvitationCallback;
import com.zegocloud.demo.cohosting.internal.invitation.common.ZEGOInvitation;
import com.zegocloud.demo.cohosting.internal.invitation.impl.CoHostProtocol;
import com.zegocloud.demo.cohosting.internal.rtc.ZEGOLiveUser;
import com.zegocloud.demo.cohosting.utils.Utils;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

public class CoHostButton extends ZEGOTextButton {

    private ZEGOInvitation invitation;

    public CoHostButton(@NonNull Context context) {
        super(context);
    }

    public CoHostButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public CoHostButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    protected void initView() {
        super.initView();
        setBackgroundResource(R.drawable.bg_cohost_btn);

        setTextColor(Color.WHITE);
        setTextSize(13);
        setGravity(Gravity.CENTER);
        DisplayMetrics displayMetrics = getContext().getResources().getDisplayMetrics();
        setPadding(Utils.dp2px(14, displayMetrics), 0, Utils.dp2px(16, displayMetrics), 0);
        setCompoundDrawablePadding(Utils.dp2px(6, displayMetrics));

        update();

        ZEGOSDKManager.getInstance().invitationService.addOutgoingInvitationListener(new OutgoingInvitationListener() {
            @Override
            public void onActionSendInvitation(int errorCode, String invitationID, String extendedData,
                List<String> errorInvitees) {
                if (invitation == null) {
                    return;
                }
                if (Objects.equals(invitationID, invitation.invitationID)) {
                    if (!TextUtils.isEmpty(invitation.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
                        if (protocol != null) {
                            if (protocol.isRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceCancelCoHostApply);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostCancelCoHostInvitation);
                            }
                        }
                        invitation.extendedData = protocol.toString();
                        update();
                    }
                }
            }

            @Override
            public void onActionCancelInvitation(int errorCode, String invitationID, List<String> errorInvitees) {
                if (invitation == null) {
                    return;
                }
                if (Objects.equals(invitationID, invitation.invitationID)) {
                    if (!TextUtils.isEmpty(invitation.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        invitation.extendedData = protocol.toString();
                        update();
                    }
                }
            }

            @Override
            public void onSendInvitationButReceiveResponseTimeout(String invitationID, List<String> invitees) {
                if (invitation == null) {
                    return;
                }
                if (Objects.equals(invitationID, invitation.invitationID)) {
                    if (!TextUtils.isEmpty(invitation.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        invitation.extendedData = protocol.toString();
                        update();
                    }
                }
            }

            @Override
            public void onSendInvitationAndIsAccepted(String invitationID, String invitee, String extendedData) {
                if (invitation == null) {
                    return;
                }
                if (Objects.equals(invitationID, invitation.invitationID)) {
                    if (!TextUtils.isEmpty(invitation.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        invitation.extendedData = protocol.toString();
                        update();
                    }
                }
            }

            @Override
            public void onSendInvitationButIsRejected(String invitationID, String invitee, String extendedData) {
                if (invitation == null) {
                    return;
                }
                if (Objects.equals(invitationID, invitation.invitationID)) {
                    if (!TextUtils.isEmpty(invitation.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        invitation.extendedData = protocol.toString();
                        update();
                    }
                }
            }
        });
    }

    public void setInvitation(ZEGOInvitation invitation) {
        this.invitation = invitation;
        update();
    }

    private static final String TAG = "CoHostButton";

    private void update() {
        if (invitation == null || TextUtils.isEmpty(invitation.extendedData)) {
            return;
        }
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol == null) {
            return;
        }

        Log.d(TAG, "update: " + protocol);
        if (protocol.isRequest()) {
            setText("Apply to CoHost");
            setCompoundDrawablesWithIntrinsicBounds(R.drawable.liveaudioroom_bottombar_cohost, 0, 0, 0);
        } else if (protocol.isInvite()) {
            setText("Invite CoHost");
            setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0);
        } else if (protocol.isCancelRequest()) {
            setText("Cancel CoHost");
            setCompoundDrawablesWithIntrinsicBounds(R.drawable.liveaudioroom_bottombar_cohost, 0, 0, 0);
        } else if (protocol.isCancelInvite()) {
            setText("Cancel Invite");
            setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0);
        } else if (protocol.isAcceptRequest()) {
            setText("Accept CoHost");
            setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0);
        } else if (protocol.isAcceptInvite()) {
            setText("Accept Invite");
            setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0);
        } else if (protocol.isRefuseInvite()) {
            setText("Refuse Invite");
            setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0);
        } else if (protocol.isRefuseRequest()) {
            setText("Refuse CoHost");
            setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0);
        }

    }

    @Override
    protected void afterClick() {
        super.afterClick();
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        ZEGOLiveUser hostUser = ZEGOSDKManager.getInstance().rtcService.getHostUser();
        if (localUser == null || hostUser == null) {
            return;
        }

        // host ,default is null
        if (invitation == null || TextUtils.isEmpty(invitation.extendedData)) {
            return;
        }
        CoHostProtocol protocol = CoHostProtocol.parse(invitation.extendedData);
        if (protocol == null) {
            return;
        }

        if (localUser.isAudience()) {
            invitation.invitees = Collections.singletonList(hostUser.userID);
            protocol.setTargetID(hostUser.userID);
            invitation.extendedData = protocol.toString();
            update();
        }

        ZEGOInvitationService invitationService = ZEGOSDKManager.getInstance().invitationService;
        if (protocol.isRequest() || protocol.isInvite()) {
            invitationService.inviteUser(protocol.getTargetID(), invitation.extendedData, new SendInvitationCallback() {
                @Override
                public void onResult(int errorCode, String invitationID, List<String> errorInvitees) {
                    if (errorCode == 0) {
                        invitation.invitationID = invitationID;
                    }
                }
            });
        } else if (protocol.isCancelInvite() || protocol.isCancelRequest()) {
            invitationService.cancelInvite(invitation, new CancelInvitationCallback() {
                @Override
                public void onResult(int errorCode, String invitationID, List<String> errorInvitees) {

                }
            });
        } else if (protocol.isRefuseRequest() || protocol.isRefuseInvite()) {
            invitationService.rejectInvite(invitation, new RejectInvitationCallback() {
                @Override
                public void onResult(int errorCode, String invitationID) {

                }
            });
        } else if (protocol.isAcceptInvite() || protocol.isAcceptRequest()) {
            invitationService.acceptInvite(invitation, new AcceptInvitationCallback() {
                @Override
                public void onResult(int errorCode, String invitationID) {
                }
            });
        }
    }


    public void onUserJoinRoom() {
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        if (localUser.isAudience()) {
            invitation = new ZEGOInvitation();
            invitation.inviter = localUser.userID;
            CoHostProtocol temp = new CoHostProtocol();
            temp.setOperatorID(localUser.userID);
            temp.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
            invitation.extendedData = temp.toString();
            update();
        }
    }
}
