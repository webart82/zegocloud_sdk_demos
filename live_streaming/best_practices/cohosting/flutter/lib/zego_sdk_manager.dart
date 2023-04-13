import 'internal/zego_express_service.dart';
import 'internal/zego_zim_service.dart';

class ZEGOSDKManager {
  ZEGOSDKManager._internal();
  factory ZEGOSDKManager() => instance;
  static final ZEGOSDKManager instance = ZEGOSDKManager._internal();

  ZegoExpressService expressService = ZegoExpressService.instance;
  ZIMService zimService = ZIMService.instance;

  ZegoUserInfo? get localUser {
    return expressService.localUser;
  }

  void init(int appID, String appSign) {
    expressService.init(appID: appID, appSign: appSign);
    zimService.init(appID: appID, appSign: appSign);
  }

  Future<void> connectUser(String userID, String userName) async {
    expressService.connectUser(userID, userName);
    zimService.connectUser(userID, userName);
  }

  void disconnectUser() {
    expressService.disconnectUser();
    zimService.disconnectUser();
  }

  ZegoUserInfo? getUser(String userID) {
    for (var user in expressService.userInfoList) {
      if (userID == user.userID) {
        return user;
      }
    }
    return null;
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID) async {
    // await these two methods
    final expressResult = await expressService.loginRoom(roomID);
    if (expressResult.errorCode != 0) {
      return expressResult;
    }

    final zimResult = await zimService.loginRoom(roomID);

    // rollback if one of them failed
    if (zimResult.errorCode != 0) {
      expressService.logoutRoom();
    }
    return zimResult;
  }

  Future<void> logoutRoom() async {
    await expressService.logoutRoom();
    await zimService.logoutRoom();
  }
}
