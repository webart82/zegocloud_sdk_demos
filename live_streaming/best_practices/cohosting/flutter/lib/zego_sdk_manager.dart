import 'internal/zego_express_service.dart';

class ZegoSDKManager {
  ZegoSDKManager._internal();
  static final ZegoSDKManager shared = ZegoSDKManager._internal();

  ZegoExpressService expressService = ZegoExpressService.shared;
  ZegoUserInfo? get localUser {
    return expressService.localUser;
  }

  void init(int appID, String appSign) {
    expressService.init(appID: appID, appSign: appSign);
  }

  Future<void> connectUser(String userID, String userName) async {
    expressService.connectUser(userID, userName);
  }

  ZegoUserInfo? getUser(String userID) {
    for (var user in expressService.userInfoList) {
      if (userID == user.userID) {
        return user;
      }
    }
    return null;
  }
}
