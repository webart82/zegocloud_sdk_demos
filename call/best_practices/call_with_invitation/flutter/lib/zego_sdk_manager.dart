import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/material.dart';

import 'interal/express/zego_express_service.dart';
import 'interal/zim/zim_service.dart';

class ZEGOSDKManager {
  ZEGOSDKManager._internal();
  factory ZEGOSDKManager() => instance;
  static final ZEGOSDKManager instance = ZEGOSDKManager._internal();

  ExpressService expressService = ExpressService.instance;
  ZIMService zimService = ZIMService.instance;

  ZegoUserInfo get localUser => ExpressService.instance.localUser;

  Future<void> init(int appID, String appSign) async {
    await expressService.init(appID: appID, appSign: appSign);
    await zimService.init(appID: appID, appSign: appSign);
  }

  Future<void> connectUser(String userID, String userName) async {
    await expressService.connectUser(userID, userName);
    await zimService.connectUser(userID, userName);
  }

  Future<void> disConnectUser(String userID, String userName) async {
    await expressService.disConnectUser(userID, userName);
    await zimService.disConnectUser();
  }

  ValueNotifier<Widget?> getVideoViewNotifier(String? userID) {
    if (userID == null || userID == expressService.localUser.userID) {
      return expressService.localVideoView;
    } else {
      return expressService.remoteVideoView;
    }
  }
}
