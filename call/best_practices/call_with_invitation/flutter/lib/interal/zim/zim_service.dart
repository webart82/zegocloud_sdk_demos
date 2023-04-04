import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:call_with_invitation/interal/zim/call_data_manager.dart';
import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/cupertino.dart';
import 'package:zego_zim/zego_zim.dart';

import 'zim_service_defines.dart';

class ZIMService {
  ZIMService._internal();
  factory ZIMService() => instance;
  static final ZIMService instance = ZIMService._internal();

  Future<void> init({required int appID, String appSign = ''}) async {
    initEventHandle();
    ZIM.create(
      ZIMAppConfig()
        ..appID = appID
        ..appSign = appSign,
    );
  }

  Future<void> uninit() async {
    uninitEventHandle();
    ZIM.getInstance()?.destroy();
  }

  Future<void> connectUser(String userID, String userName) async {
    ZIMUserInfo userInfo = ZIMUserInfo();
    userInfo.userID = userID;
    userInfo.userName = userName;
    zimUserInfo = userInfo;
    await ZIM.getInstance()?.login(userInfo);
  }

  Future<void> disConnectUser() async {
    ZIM.getInstance()!.logout();
  }

  Future<ZegoSendInvitationResult> sendInvitation({
    required List<String> invitees,
    required ZegoCallType callType,
    int timeout = 60,
    String extendedData = '',
  }) async {
    final config = ZIMCallInviteConfig()
      ..extendedData = extendedData
      ..timeout = timeout;
    return ZIM.getInstance()!.callInvite(invitees, config).then((ZIMCallInvitationSentResult zimResult) {
      ZegoCallStateManager.instance.createCallData(
        zimResult.callID,
        ZegoUserInfo(userID: zimUserInfo?.userID ?? '', userName: zimUserInfo?.userName ?? ''),
        ZegoUserInfo(userID: invitees.first, userName: ''),
        ZegoCallUserState.inviting,
        callType,
      );
      return ZegoSendInvitationResult(
        invitationID: zimResult.callID,
        errorInvitees: {
          for (var element in zimResult.info.errorInvitees)
            element.userID: ZegoCallUserState.values[element.state.index]
        },
      );
    }).catchError((error) {
      return ZegoSendInvitationResult(
        invitationID: '',
        errorInvitees: {},
        error: error,
      );
    });
  }

  Future<ZegoCancelInvitationResult> cancelInvitation({
    required String invitationID,
    required List<String> invitees,
    String extendedData = '',
  }) async {
    ZegoCallStateManager.instance.clearCallData();
    return ZIM
        .getInstance()!
        .callCancel(invitees, invitationID, ZIMCallCancelConfig()..extendedData = extendedData)
        .then((ZIMCallCancelSentResult zimResult) {
      return ZegoCancelInvitationResult(
        errorInvitees: zimResult.errorInvitees,
      );
    }).catchError((error) {
      return ZegoCancelInvitationResult(
        errorInvitees: invitees,
        error: error,
      );
    });
  }

  Future<ZegoResponseInvitationResult> rejectInvitation({
    required String invitationID,
    String extendedData = '',
  }) {
    if (invitationID == ZegoCallStateManager.instance.callData?.callID) {
      ZegoCallStateManager.instance.clearCallData();
    }
    return ZIM
        .getInstance()!
        .callReject(invitationID, ZIMCallRejectConfig()..extendedData = extendedData)
        .then((ZIMCallRejectionSentResult zimResult) {
      return const ZegoResponseInvitationResult();
    }).catchError((error) {
      return ZegoResponseInvitationResult(
        error: error,
      );
    });
  }

  Future<ZegoResponseInvitationResult> acceptInvitation({
    required String invitationID,
    String extendedData = '',
  }) {
    return ZIM
        .getInstance()!
        .callAccept(invitationID, ZIMCallAcceptConfig()..extendedData = extendedData)
        .then((ZIMCallAcceptanceSentResult zimResult) {
      ZegoCallStateManager.instance.updateCall(invitationID, ZegoCallUserState.accepted);
      return const ZegoResponseInvitationResult();
    }).catchError((error) {
      return ZegoResponseInvitationResult(
        error: error,
      );
    });
  }

  void onCallInvitationReceived(ZIM zim, ZIMCallInvitationReceivedInfo info, String callID) {
    if (ZegoCallStateManager.instance.callData != null) {
      rejectInvitation(invitationID: callID, extendedData: 'busy');
      return;
    }
    Map<String, dynamic> callInfoMap = {};
    try {
      callInfoMap = json.decode(info.extendedData) as Map<String, dynamic>;
    } on FormatException {
      debugPrint('The info.extendedData is not valid JSON');
    }
    ZegoCallType type = callInfoMap['type'] == ZegoCallType.video.index ? ZegoCallType.video : ZegoCallType.voice;
    String inviterName = callInfoMap['inviterName'] as String;
    ZegoCallStateManager.instance.createCallData(
      callID,
      ZegoUserInfo(userID: info.inviter, userName: inviterName),
      ZegoUserInfo(userID: zimUserInfo?.userID ?? '', userName: zimUserInfo?.userName ?? ''),
      ZegoCallUserState.received,
      type,
    );
    incomingCallInvitationReceivedStreamCtrl.add(IncomingCallInvitationReveivedEvent(
      callID,
      info.inviter,
      info.extendedData,
    ));
  }

  void onCallInvitationAccepted(ZIM zim, ZIMCallInvitationAcceptedInfo info, String callID) {
    ZegoCallStateManager.instance.updateCall(callID, ZegoCallUserState.accepted);
    outgoingCallInvitationAcceptedStreamCtrl
        .add(OutgoingCallInvitationAcceptedEvent(callID, info.invitee, info.extendedData));
  }

  void onCallInvitationCancelled(ZIM zim, ZIMCallInvitationCancelledInfo info, String callID) {
    ZegoCallStateManager.instance.updateCall(callID, ZegoCallUserState.cancelled);
    ZegoCallStateManager.instance.clearCallData();
    incomingCallInvitationCanceledStreamCtrl
        .add(IncomingCallInvitationCanceledEvent(callID, info.inviter, info.extendedData));
  }

  void onCallInvitationRejected(ZIM zim, ZIMCallInvitationRejectedInfo info, String callID) {
    ZegoCallStateManager.instance.updateCall(callID, ZegoCallUserState.rejected);
    ZegoCallStateManager.instance.clearCallData();
    outgoingCallInvitationRejectedStreamCtrl
        .add(OutgoingCallInvitationRejectedEvent(callID, info.invitee, info.extendedData));
  }

  void onCallInvitationTimeout(ZIM zim, String callID) {
    ZegoCallStateManager.instance.updateCall(callID, ZegoCallUserState.offline);
    ZegoCallStateManager.instance.clearCallData();
    incomingCallInvitationTimeoutStreamCtrl.add(IncomingCallInvitationTimeoutEvent(callID));
  }

  void onCallInviteesAnsweredTimeout(ZIM zim, List<String> invitees, String callID) {
    ZegoCallStateManager.instance.updateCall(callID, ZegoCallUserState.offline);
    ZegoCallStateManager.instance.clearCallData();
    outgoingCallInvitationTimeoutStreamCtrl.add(OutgoingCallInvitationTimeoutEvent(callID, invitees));
  }

  void onConnectionStateChanged(ZIM zim, ZIMConnectionState state, ZIMConnectionEvent event, Map extendedData) {
    zimConnectionStateStreamCtrl.add(ZIMServiceConnectionStateChangedEvent(state, event));
  }

  void uninitEventHandle() {
    ZIMEventHandler.onCallInvitationRejected = null;
    ZIMEventHandler.onCallInvitationAccepted = null;
    ZIMEventHandler.onCallInvitationRejected = null;
    ZIMEventHandler.onCallInvitationCancelled = null;
    ZIMEventHandler.onCallInvitationTimeout = null;
    ZIMEventHandler.onCallInviteesAnsweredTimeout = null;
    ZIMEventHandler.onConnectionStateChanged = null;
  }

  void initEventHandle() {
    ZIMEventHandler.onCallInvitationReceived =
        (zim, info, callID) => ZIMService.instance.onCallInvitationReceived(zim, info, callID);
    ZIMEventHandler.onCallInvitationAccepted =
        (zim, info, callID) => ZIMService.instance.onCallInvitationAccepted(zim, info, callID);
    ZIMEventHandler.onCallInvitationCancelled =
        (zim, info, callID) => ZIMService.instance.onCallInvitationCancelled(zim, info, callID);
    ZIMEventHandler.onCallInvitationRejected =
        (zim, info, callID) => ZIMService.instance.onCallInvitationRejected(zim, info, callID);
    ZIMEventHandler.onCallInvitationTimeout = (zim, callID) => ZIMService.instance.onCallInvitationTimeout(zim, callID);
    ZIMEventHandler.onCallInviteesAnsweredTimeout =
        (zim, invitees, callID) => ZIMService.instance.onCallInviteesAnsweredTimeout(zim, invitees, callID);
    ZIMEventHandler.onConnectionStateChanged = (zim, state, event, extendedData) =>
        ZIMService.instance.onConnectionStateChanged(zim, state, event, extendedData);
  }

  ZIMUserInfo? zimUserInfo;
  StreamController<IncomingCallInvitationReveivedEvent> incomingCallInvitationReceivedStreamCtrl =
      StreamController<IncomingCallInvitationReveivedEvent>.broadcast();
  StreamController<OutgoingCallInvitationAcceptedEvent> outgoingCallInvitationAcceptedStreamCtrl =
      StreamController<OutgoingCallInvitationAcceptedEvent>.broadcast();
  StreamController<IncomingCallInvitationCanceledEvent> incomingCallInvitationCanceledStreamCtrl =
      StreamController<IncomingCallInvitationCanceledEvent>.broadcast();
  StreamController<OutgoingCallInvitationRejectedEvent> outgoingCallInvitationRejectedStreamCtrl =
      StreamController<OutgoingCallInvitationRejectedEvent>.broadcast();
  StreamController<IncomingCallInvitationTimeoutEvent> incomingCallInvitationTimeoutStreamCtrl =
      StreamController<IncomingCallInvitationTimeoutEvent>.broadcast();
  StreamController<OutgoingCallInvitationTimeoutEvent> outgoingCallInvitationTimeoutStreamCtrl =
      StreamController<OutgoingCallInvitationTimeoutEvent>.broadcast();
  StreamController<ZIMServiceConnectionStateChangedEvent> zimConnectionStateStreamCtrl =
      StreamController<ZIMServiceConnectionStateChangedEvent>.broadcast();
}
