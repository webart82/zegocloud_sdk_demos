import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:call_with_invitation/interal/im/zim_service_call_data_manager.dart';
import 'package:call_with_invitation/interal/im/zim_service_event.dart';
import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

import 'package:zego_zim/zego_zim.dart';

import 'zim_service_defines.dart';
import 'zim_service_enum.dart';

class ZIMService with ZIMServiceEvent {
  ZIMService._internal();

  static final ZIMService shared = ZIMService._internal();
  ZIMUserInfo? zimUserInfo;

  StreamController<ZIMReveiveCallEvent> receiveCallStreamCtrl =
      StreamController<ZIMReveiveCallEvent>.broadcast();
  StreamController<ZIMAcceptCallEvent> acceptCallStreamCtrl =
      StreamController<ZIMAcceptCallEvent>.broadcast();
  StreamController<ZIMCancelCallEvent> cancelCallStreamCtrl =
      StreamController<ZIMCancelCallEvent>.broadcast();
  StreamController<ZIMRejectCallEvent> rejectCallStreamCtrl =
      StreamController<ZIMRejectCallEvent>.broadcast();
  StreamController<ZIMTimeOutCallEvent> timeoutCallStreamCtrl =
      StreamController<ZIMTimeOutCallEvent>.broadcast();
  StreamController<ZIMAnswerTimeOutCallEvent> answerTimeoutCallStreamCtrl =
      StreamController<ZIMAnswerTimeOutCallEvent>.broadcast();
  StreamController<ZIMConnectionStateChangeEvent> zimConnectionStateStreamCtrl =
      StreamController<ZIMConnectionStateChangeEvent>.broadcast();

  Future<void> init({required int appID, String appSign = ''}) async {
    ZIM.create(ZIMAppConfig()
      ..appID = appID
      ..appSign = appSign);

    initEventHandle();
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
    ZIM.getInstance()?.login(userInfo);
  }

  Future<ZegoSendInvitationResult> sendInvitation({
    required List<String> invitees,
    required int timeout,
    String extendedData = '',
  }) async {
    final config = ZIMCallInviteConfig()
      ..extendedData = extendedData
      ..timeout = timeout;
    return ZIM
        .getInstance()!
        .callInvite(invitees, config)
        .then((ZIMCallInvitationSentResult zimResult) {
      ZegoCallDataManager.shared.callData = ZegoCallData(
          inviter: ZegoUserInfo(
              userID: zimUserInfo?.userID ?? '',
              userName: zimUserInfo?.userName ?? ''),
          invitee: ZegoUserInfo(userID: invitees.first, userName: ''),
          callType: ZegoCallType.video,
          callID: zimResult.callID);
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
    ZegoCallDataManager.shared.clear();
    return ZIM
        .getInstance()!
        .callCancel(invitees, invitationID,
            ZIMCallCancelConfig()..extendedData = extendedData)
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

  Future<ZegoResponseInvitationResult> refuseInvitation({
    required String invitationID,
    String extendedData = '',
  }) {
    if (invitationID == ZegoCallDataManager.shared.callData?.callID) {
      ZegoCallDataManager.shared.clear();
    }
    return ZIM
        .getInstance()!
        .callReject(
            invitationID, ZIMCallRejectConfig()..extendedData = extendedData)
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
        .callAccept(
            invitationID, ZIMCallAcceptConfig()..extendedData = extendedData)
        .then((ZIMCallAcceptanceSentResult zimResult) {
      ZegoCallDataManager.shared
          .updateCall(invitationID, ZegoCallUserState.accepted);
      return const ZegoResponseInvitationResult();
    }).catchError((error) {
      return ZegoResponseInvitationResult(
        error: error,
      );
    });
  }

  void onCallInvitationReceived(
      ZIM zim, ZIMCallInvitationReceivedInfo info, String callID) {
    if (ZegoCallDataManager.shared.callData != null) {
      refuseInvitation(invitationID: callID);
      return;
    }
    Map<String, dynamic> callInfoMap = json.decode(info.extendedData);
    ZegoCallType type = callInfoMap['type'];
    ZegoCallDataManager.shared.callData = ZegoCallData(
        inviter: ZegoUserInfo(userID: info.inviter, userName: ''),
        invitee: ZegoUserInfo(
            userID: zimUserInfo?.userID ?? '',
            userName: zimUserInfo?.userName ?? ''),
        callType: type,
        callID: callID);
    receiveCallStreamCtrl.add(ZIMReveiveCallEvent(
      callID,
      info.inviter,
      info.extendedData,
    ));
  }

  void onCallInvitationAccepted(
      ZIM zim, ZIMCallInvitationAcceptedInfo info, String callID) {
    ZegoCallDataManager.shared.updateCall(callID, ZegoCallUserState.accepted);
    acceptCallStreamCtrl
        .add(ZIMAcceptCallEvent(callID, info.invitee, info.extendedData));
  }

  void onCallInvitationCancelled(
      ZIM zim, ZIMCallInvitationCancelledInfo info, String callID) {
    ZegoCallDataManager.shared.updateCall(callID, ZegoCallUserState.cancelled);
    ZegoCallDataManager.shared.clear();
    cancelCallStreamCtrl
        .add(ZIMCancelCallEvent(callID, info.inviter, info.extendedData));
  }

  void onCallInvitationRejected(
      ZIM zim, ZIMCallInvitationRejectedInfo info, String callID) {
    ZegoCallDataManager.shared.updateCall(callID, ZegoCallUserState.rejected);
    ZegoCallDataManager.shared.clear();
    rejectCallStreamCtrl
        .add(ZIMRejectCallEvent(callID, info.invitee, info.extendedData));
  }

  void onCallInvitationTimeout(ZIM zim, String callID) {
    ZegoCallDataManager.shared.updateCall(callID, ZegoCallUserState.offline);
    ZegoCallDataManager.shared.clear();
    timeoutCallStreamCtrl.add(ZIMTimeOutCallEvent(callID));
  }

  void onCallInviteesAnsweredTimeout(
      ZIM zim, List<String> invitees, String callID) {
    ZegoCallDataManager.shared.updateCall(callID, ZegoCallUserState.offline);
    ZegoCallDataManager.shared.clear();
    answerTimeoutCallStreamCtrl
        .add(ZIMAnswerTimeOutCallEvent(callID, invitees));
  }

  void onConnectionStateChanged(ZIM zim, ZIMConnectionState state,
      ZIMConnectionEvent event, Map extendedData) {
    zimConnectionStateStreamCtrl
        .add(ZIMConnectionStateChangeEvent(state, event));
  }
}
