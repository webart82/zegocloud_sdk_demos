import 'package:zego_express_engine/zego_express_engine.dart';
import 'zego_express_service_event.dart';

export 'zego_service_define.dart';

class ZegoExpressService with ZegoExpressServiceEvent {
  ZegoExpressService._internal();
  static final ZegoExpressService shared = ZegoExpressService._internal();

  ZegoUserInfo? localUser;
  String room = '';

  Future<void> init({
    required int appID,
    String appSign = '',
    ZegoScenario scenario = ZegoScenario.Default,
  }) async {
    final profile = ZegoEngineProfile(appID, scenario, appSign: appSign);
    initEventHandle();

    await ZegoExpressEngine.createEngineWithProfile(profile);
    ZegoExpressEngine.setEngineConfig(ZegoEngineConfig(advancedConfig: {
      'notify_remote_device_unknown_status': 'true',
      'notify_remote_device_init_status': 'true',
    }));
  }

  Future<void> uninit() async {
    uninitEventHandle();

    await ZegoExpressEngine.destroyEngine();
  }

  void connectUser(String id, String name) {
    localUser = ZegoUserInfo(userID: id, userName: name);
  }

  Future<ZegoRoomLoginResult?> joinRoom(String roomID) async {
    if (localUser == null) {
      return null;
    }
    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(localUser!.userID, localUser!.userName),
      config: ZegoRoomConfig(0, true, ''),
    );
    if (joinRoomResult.errorCode == 0) {
      room = roomID;
    }
    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> leaveRoom() async {
    final leaveResult = await ZegoExpressEngine.instance.logoutRoom();
    if (leaveResult.errorCode == 0) {
      room = '';
    }
    return leaveResult;
  }

  void useFrontFacingCamera(bool isFrontFacing) {
    ZegoExpressEngine.instance.useFrontCamera(isFrontFacing);
  }

  void enableVideoMirroring(bool isVideoMirror) {
    ZegoExpressEngine.instance.setVideoMirrorMode(
      isVideoMirror
          ? ZegoVideoMirrorMode.BothMirror
          : ZegoVideoMirrorMode.NoMirror,
    );
  }

  void setAudioOutputToSpeaker(bool useSpeaker) {
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(useSpeaker);
  }

  void turnCameraOn(bool isOn) {
    ZegoExpressEngine.instance.enableCamera(isOn);
  }

  void turnMicrophoneOn(bool isOn) {
    ZegoExpressEngine.instance.muteMicrophone(!isOn);
  }

  Future<void> startPlayingStream(String streamID) async {
    await ZegoExpressEngine.instance.startPlayingStream(streamID);
  }

  Future<void> stopPlayingStream(String streamID) async {
    await ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }


}
