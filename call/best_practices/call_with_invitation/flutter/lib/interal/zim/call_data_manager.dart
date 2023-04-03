import 'package:call_with_invitation/zego_user_Info.dart';

import 'zim_service_defines.dart';

class ZegoCallDataManager {
  ZegoCallDataManager._internal();
  static final ZegoCallDataManager instance = ZegoCallDataManager._internal();
  ZegoCallDataManager({this.callData});

  ZegoCallData? callData;

  bool get busy => callData != null;

  void createCall(
      String callID, ZegoUserInfo inviter, ZegoUserInfo invitee, ZegoCallUserState state, ZegoCallType callType) {
    callData = ZegoCallData(inviter: inviter, invitee: invitee, state: state, callType: callType, callID: callID);
  }

  void updateCall(String callID, ZegoCallUserState state) {
    if (callID.isNotEmpty && callID == callData?.callID) {
      callData?.state = state;
    }
  }

  void clear() => callData = null;
}

class ZegoCallData {
  ZegoCallData({
    required this.inviter,
    required this.invitee,
    required this.callType,
    required this.callID,
    this.state = ZegoCallUserState.inviting,
  });

  final ZegoUserInfo inviter;
  final ZegoUserInfo invitee;
  final ZegoCallType callType;
  final String callID;
  ZegoCallUserState state;
}
