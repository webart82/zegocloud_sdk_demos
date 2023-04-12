package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.graphics.Color;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.Gravity;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.ZEGOSDKManager;
import com.zegocloud.demo.cohosting.internal.ZEGOExpressService;
import com.zegocloud.demo.cohosting.internal.ZEGOInvitationService;
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

    private ZEGOInvitation mInvitationData;

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

        setTextColor(Color.WHITE);
        setTextSize(13);
        setGravity(Gravity.CENTER);
        DisplayMetrics displayMetrics = getContext().getResources().getDisplayMetrics();
        setPadding(Utils.dp2px(14, displayMetrics), 0, Utils.dp2px(16, displayMetrics), 0);
        setCompoundDrawablePadding(Utils.dp2px(6, displayMetrics));

        ZEGOSDKManager.getInstance().invitationService.addOutgoingInvitationListener(new OutgoingInvitationListener() {
            @Override
            public void onActionSendInvitation(int errorCode, String invitationID, String extendedData,
                List<String> errorInvitees) {
                if (mInvitationData == null) {
                    return;
                }
                if (Objects.equals(invitationID, mInvitationData.invitationID)) {
                    if (!TextUtils.isEmpty(mInvitationData.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(mInvitationData.extendedData);
                        if (protocol != null) {
                            if (protocol.isRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceCancelCoHostApply);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostCancelCoHostInvitation);
                            }
                        }
                        mInvitationData.extendedData = protocol.toString();
                        updateUI();
                    }
                }
            }

            @Override
            public void onActionCancelInvitation(int errorCode, String invitationID, List<String> errorInvitees) {
                if (mInvitationData == null) {
                    return;
                }
                if (Objects.equals(invitationID, mInvitationData.invitationID)) {
                    if (!TextUtils.isEmpty(mInvitationData.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(mInvitationData.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        mInvitationData.extendedData = protocol.toString();
                        updateUI();
                    }
                }
            }

            @Override
            public void onSendInvitationButReceiveResponseTimeout(String invitationID, List<String> invitees) {
                if (mInvitationData == null) {
                    return;
                }
                if (Objects.equals(invitationID, mInvitationData.invitationID)) {
                    if (!TextUtils.isEmpty(mInvitationData.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(mInvitationData.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        mInvitationData.extendedData = protocol.toString();
                        updateUI();
                    }
                }
            }

            @Override
            public void onSendInvitationAndIsAccepted(String invitationID, String invitee, String extendedData) {
                if (mInvitationData == null) {
                    return;
                }
                if (Objects.equals(invitationID, mInvitationData.invitationID)) {
                    if (!TextUtils.isEmpty(mInvitationData.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(mInvitationData.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        mInvitationData.extendedData = protocol.toString();
                        updateUI();
                    }
                }
            }

            @Override
            public void onSendInvitationButIsRejected(String invitationID, String invitee, String extendedData) {
                if (mInvitationData == null) {
                    return;
                }
                if (Objects.equals(invitationID, mInvitationData.invitationID)) {
                    if (!TextUtils.isEmpty(mInvitationData.extendedData)) {
                        CoHostProtocol protocol = CoHostProtocol.parse(mInvitationData.extendedData);
                        if (protocol != null) {
                            if (protocol.isCancelRequest()) {
                                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                            } else {
                                protocol.setActionType(CoHostProtocol.HostInviteAudienceToBecomeCoHost);
                            }
                        }
                        mInvitationData.extendedData = protocol.toString();
                        updateUI();
                    }
                }
            }
        });
    }

    public void setInvitation(ZEGOInvitation invitation) {
        this.mInvitationData = invitation;
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        mInvitationData.inviter = localUser.userID;
        updateUI();
    }

    private static final String TAG = "CoHostButton";

    @Override
    protected void afterClick() {
        super.afterClick();
        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        ZEGOLiveUser hostUser = ZEGOSDKManager.getInstance().rtcService.getHostUser();
        if (localUser == null || hostUser == null) {
            return;
        }

        ZEGOExpressService rtcService = ZEGOSDKManager.getInstance().rtcService;
        if (localUser.isCoHost()) {
            rtcService.openMicrophone(false);
            rtcService.enableCamera(false);
            rtcService.stopPublishLocalAudioVideo();
        } else {
            if (mInvitationData == null) {
                return;
            }
            CoHostProtocol protocol = CoHostProtocol.parse(mInvitationData.extendedData);
            if (protocol == null) {
                protocol = new CoHostProtocol();
            }
            if (localUser.isAudience()) {
                mInvitationData.invitees = Collections.singletonList(hostUser.userID);
                protocol.setOperatorID(localUser.userID);
                protocol.setTargetID(hostUser.userID);
                protocol.setActionType(CoHostProtocol.AudienceApplyToBecomeCoHost);
                mInvitationData.extendedData = protocol.toString();
            }

            ZEGOInvitationService invitationService = ZEGOSDKManager.getInstance().invitationService;
            if (protocol.isRequest() || protocol.isInvite()) {
                invitationService.inviteUser(protocol.getTargetID(), mInvitationData.extendedData,
                    new SendInvitationCallback() {
                        @Override
                        public void onResult(int errorCode, String invitationID, List<String> errorInvitees) {
                            if (errorCode == 0) {
                                mInvitationData.invitationID = invitationID;
                            }
                        }
                    });
            } else if (protocol.isCancelInvite() || protocol.isCancelRequest()) {
                invitationService.cancelInvite(mInvitationData, new CancelInvitationCallback() {
                    @Override
                    public void onResult(int errorCode, String invitationID, List<String> errorInvitees) {

                    }
                });
            } else if (protocol.isRefuseRequest() || protocol.isRefuseInvite()) {
                invitationService.rejectInvite(mInvitationData, new RejectInvitationCallback() {
                    @Override
                    public void onResult(int errorCode, String invitationID) {

                    }
                });
            } else if (protocol.isAcceptInvite() || protocol.isAcceptRequest()) {
                invitationService.acceptInvite(mInvitationData, new AcceptInvitationCallback() {
                    @Override
                    public void onResult(int errorCode, String invitationID) {
                    }
                });
            }
        }
    }

    public void updateUI() {
        if (mInvitationData == null) {
            return;
        }

        ZEGOLiveUser localUser = ZEGOSDKManager.getInstance().rtcService.getLocalUser();
        ZEGOInvitationService invitationService = ZEGOSDKManager.getInstance().invitationService;
        ZEGOInvitation zegoInvitation = invitationService.getZEGOInvitation(mInvitationData.invitationID);
        if (localUser.isHost()) {

        } else if (localUser.isCoHost()) {
            setText("End");
            setBackgroundResource(R.drawable.livestreaming_bg_end_cohost_btn);
            setCompoundDrawablesWithIntrinsicBounds(R.drawable.liveaudioroom_bottombar_cohost, 0, 0, 0);
        } else if (localUser.isAudience()) {
            if (zegoInvitation == null || zegoInvitation.isFinished()) {
                setText("Apply to CoHost");
                setBackgroundResource(R.drawable.bg_cohost_btn);
                setCompoundDrawablesWithIntrinsicBounds(R.drawable.liveaudioroom_bottombar_cohost, 0, 0, 0);
            } else {
                setText("Cancel CoHost");
                setBackgroundResource(R.drawable.bg_cohost_btn);
                setCompoundDrawablesWithIntrinsicBounds(R.drawable.liveaudioroom_bottombar_cohost, 0, 0, 0);
            }
        }
    }
}
