import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/material.dart';

import 'interal/express/zego_express_service.dart';
import 'interal/zim/zim_service.dart';
import 'interal/zim/zim_service_defines.dart';

class ZEGOSDKManager {
  ZEGOSDKManager._internal();
  static final ZEGOSDKManager instance = ZEGOSDKManager._internal();

  ZegoExpressService expressService = ZegoExpressService.instance;
  ZIMService zimService = ZIMService.instance;
  ZegoUserInfo get localUser => ZegoExpressService.instance.localUser;

  Future<void> init(int appID, String appSign) async {
    await expressService.init(appID: appID, appSign: appSign);
    await zimService.init(appID: appID, appSign: appSign);
  }

  Future<void> connectUser(String userID, String userName) async {
    await expressService.connectUser(userID, userName);
    await zimService.connectUser(userID, userName);
  }

  ValueNotifier<Widget?> getVideoViewNotifier(String? userID) {
    if (userID == null || userID == expressService.localUser.userID) {
      return expressService.localVideoView;
    } else {
      return expressService.remoteVideoView;
    }
  }

  Future<ZegoSendInvitationResult> sendInvitation({
    required List<String> invitees,
    required ZegoCallType callType,
    int timeout = 60,
    String extendedData = '',
  }) async {
    return await zimService.sendInvitation(
        invitees: invitees, timeout: timeout, callType: callType, extendedData: extendedData);
  }

  Future<ZegoCancelInvitationResult> cancelInvitation({
    required String invitationID,
    required List<String> invitees,
    String extendedData = '',
  }) async {
    return zimService.cancelInvitation(invitationID: invitationID, invitees: invitees, extendedData: extendedData);
  }

  Future<ZegoResponseInvitationResult> refuseInvitation({
    required String invitationID,
    String extendedData = '',
  }) {
    return zimService.refuseInvitation(invitationID: invitationID, extendedData: extendedData);
  }

  Future<ZegoResponseInvitationResult> acceptInvitation({
    required String invitationID,
    String extendedData = '',
  }) {
    return zimService.acceptInvitation(invitationID: invitationID, extendedData: extendedData);
  }
}
