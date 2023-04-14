import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';

import 'zego_service_define.dart';

export 'package:live_streaming_with_cohosting/define.dart';
export 'zego_service_define.dart';
export 'package:zego_express_engine/zego_express_engine.dart';

class ExpressService {
  ExpressService._internal();
  factory ExpressService() => instance;
  static final ExpressService instance = ExpressService._internal();

  String room = '';
  ZegoUserInfo? localUser;
  List<ZegoUserInfo> userInfoList = [];
  Map<String, String> streamMap = {};

  Future<void> init({
    required int appID,
    String appSign = '',
    ZegoScenario scenario = ZegoScenario.Broadcast,
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

  Future<void> connectUser(String id, String name) async {
    localUser = ZegoUserInfo(userID: id, userName: name);
  }

  Future<void> disconnectUser() async {
    localUser = null;
  }

  ZegoUserInfo? getUserInfo(String userID) {
    for (var user in userInfoList) {
      if (user.userID == userID) {
        return user;
      }
    }
    return null;
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID) async {
    final loginRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(localUser?.userID ?? '', localUser?.userName ?? ''),
      config: ZegoRoomConfig(0, true, ''),
    );
    if (loginRoomResult.errorCode == 0) {
      room = roomID;
    }
    return loginRoomResult;
  }

  Future<ZegoRoomLogoutResult> logoutRoom() async {
    room = '';
    userInfoList.clear();
    resertLocalUser();
    streamMap.clear();
    final leaveResult = await ZegoExpressEngine.instance.logoutRoom();
    return leaveResult;
  }

  void resertLocalUser() {
    localUser?.streamID = null;
    localUser?.isCamerOnNotifier.value = false;
    localUser?.isMicOnNotifier.value = false;
    localUser?.videoViewNotifier.value = null;
    localUser?.viewID = -1;
    localUser?.roleNotifier.value = ZegoLiveRole.audience;
  }

  void useFrontFacingCamera(bool isFrontFacing) {
    ZegoExpressEngine.instance.useFrontCamera(isFrontFacing);
  }

  void enableVideoMirroring(bool isVideoMirror) {
    ZegoExpressEngine.instance.setVideoMirrorMode(
      isVideoMirror ? ZegoVideoMirrorMode.BothMirror : ZegoVideoMirrorMode.NoMirror,
    );
  }

  void setAudioOutputToSpeaker(bool useSpeaker) {
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(useSpeaker);
  }

  void turnCameraOn(bool isOn) {
    localUser?.isCamerOnNotifier.value = isOn;
    final extraInfo = jsonEncode({
      'mic': localUser?.isMicOnNotifier.value ?? false ? 'on' : 'off',
      'cam': isOn ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.enableCamera(isOn);
  }

  void turnMicrophoneOn(bool isOn) {
    localUser?.isMicOnNotifier.value = isOn;
    final extraInfo = jsonEncode({
      'mic': isOn ? 'on' : 'off',
      'cam': localUser?.isCamerOnNotifier.value ?? false ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.muteMicrophone(!isOn);
  }

  Future<void> startPlayingStream(String streamID) async {
    String? userID = streamMap[streamID];
    ZegoUserInfo? userInfo = getUserInfo(userID ?? '');
    if (userInfo != null) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) {
        userInfo.viewID = viewID;
      }).then((videoViewWidget) {
        userInfo.videoViewNotifier.value = videoViewWidget;
      });
      ZegoCanvas canvas = ZegoCanvas(userInfo.viewID, viewMode: ZegoViewMode.AspectFill);
      await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }
  }

  Future<void> stopPlayingStream(String streamID) async {
    String? userID = streamMap[streamID];
    ZegoUserInfo? userInfo = getUserInfo(userID ?? '');
    if (userInfo != null) {
      userInfo.streamID = '';
      userInfo.videoViewNotifier.value = null;
      userInfo.viewID = -1;
    }
    await ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }

  Future<void> startPreview() async {
    if (localUser != null) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) {
        localUser!.viewID = viewID;
      }).then((videoViewWidget) {
        localUser!.videoViewNotifier.value = videoViewWidget;
      });

      final previewCanvas = ZegoCanvas(
        localUser!.viewID,
        viewMode: ZegoViewMode.AspectFill,
      );
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    }
  }

  Future<void> stopPreview() async {
    localUser?.videoViewNotifier.value = null;
    localUser?.viewID = -1;
    await ZegoExpressEngine.instance.stopPreview();
  }

  Future<void> startPublishingStream(String streamID) async {
    localUser?.streamID = streamID;
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> stopPublishingStream() async {
    localUser?.streamID = null;
    localUser?.isCamerOnNotifier.value = false;
    localUser?.isMicOnNotifier.value = false;
    await ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<ZegoIMSendCustomCommandResult> sendCommandMessage(String command, List<String> toUserList) async {
    List<ZegoUser> users = [];
    for (var userID in toUserList) {
      ZegoUser user = ZegoUser(userID, '');
      users.add(user);
    }
    ZegoIMSendCustomCommandResult result = await ZegoExpressEngine.instance.sendCustomCommand(room, command, users);
    return result;
  }

  final roomUserListUpdateStreamCtrl = StreamController<ZegoRoomUserListUpdateEvent>.broadcast();
  final streamListUpdateStreamCtrl = StreamController<ZegoRoomStreamListUpdateEvent>.broadcast();
  final customCommandStreamCtrl = StreamController<ZegoRoomCustomSignalingEvent>.broadcast();
  final roomStreamExtraInfoStreamCtrl = StreamController<ZegoRoomStreamExtraInfoEvent>.broadcast();
  final roomStateChangedStreamCtrl = StreamController<ZegoRoomStateEvent>.broadcast();

  void uninitEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onIMRecvCustomCommand = null;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = null;
    ZegoExpressEngine.onRoomStateChanged = null;
  }

  void initEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = ExpressService.instance.onRoomStreamUpdate;

    ZegoExpressEngine.onRoomUserUpdate = ExpressService.instance.onRoomUserUpdate;

    ZegoExpressEngine.onIMRecvCustomCommand = ExpressService.instance.onIMRecvCustomCommand;

    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = ExpressService.instance.onRoomStreamExtraInfoUpdate;
    ZegoExpressEngine.onRoomStateChanged = ExpressService.instance.onRoomStateChanged;
  }

  Future<void> onRoomStreamUpdate(
      String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) async {
    for (ZegoStream stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        streamMap[stream.streamID] = stream.user.userID;
        ZegoUserInfo? userInfo = getUserInfo(stream.user.userID);
        if (userInfo == null) {
          userInfo = ZegoUserInfo(userID: stream.user.userID, userName: stream.user.userName);
          userInfoList.add(userInfo);
        }
        userInfo.streamID = stream.streamID;
        Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
        bool isMicOn = (extraInfoMap['mic'] == 'on') ? true : false;
        bool isCameraOn = (extraInfoMap['cam'] == 'on') ? true : false;
        userInfo.isCamerOnNotifier.value = isCameraOn;
        userInfo.isMicOnNotifier.value = isMicOn;
        startPlayingStream(stream.streamID);
      } else {
        streamMap[stream.streamID] = '';
        ZegoUserInfo? userInfo = getUserInfo(stream.user.userID);
        userInfo?.streamID = '';
        userInfo?.isCamerOnNotifier.value = false;
        userInfo?.isMicOnNotifier.value = false;
        stopPlayingStream(stream.streamID);
      }
    }
    streamListUpdateStreamCtrl.add(ZegoRoomStreamListUpdateEvent(roomID, updateType, streamList, extendedData));
  }

  void onRoomUserUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoUser> userList,
  ) {
    if (updateType == ZegoUpdateType.Add) {
      for (var user in userList) {
        ZegoUserInfo? userInfo = getUserInfo(user.userID);
        if (userInfo == null) {
          userInfo = ZegoUserInfo(userID: user.userID, userName: user.userName);
          userInfoList.add(userInfo);
        } else {
          userInfo.userID = user.userID;
          userInfo.userName = user.userName;
        }
      }
    } else {
      for (var user in userList) {
        userInfoList.removeWhere((element) {
          return element.userID == user.userID;
        });
      }
    }
    roomUserListUpdateStreamCtrl.add(ZegoRoomUserListUpdateEvent(roomID, updateType, userList));
  }

  void onIMRecvCustomCommand(String roomID, ZegoUser fromUser, String command) {
    customCommandStreamCtrl.add(ZegoRoomCustomSignalingEvent(roomID, fromUser, command));
  }

  void onRoomStreamExtraInfoUpdate(String roomID, List<ZegoStream> streamList) {
    for (var user in userInfoList) {
      for (ZegoStream stream in streamList) {
        if (stream.streamID == user.streamID) {
          Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
          bool isMicOn = (extraInfoMap['mic'] == 'on') ? true : false;
          bool isCameraOn = (extraInfoMap['cam'] == 'on') ? true : false;
          user.isCamerOnNotifier.value = isCameraOn;
          user.isMicOnNotifier.value = isMicOn;
        }
      }
    }
    roomStreamExtraInfoStreamCtrl.add(ZegoRoomStreamExtraInfoEvent(roomID, streamList));
  }

  void onRoomStateChanged(
      String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData) {
    roomStateChangedStreamCtrl.add(ZegoRoomStateEvent(roomID, reason, errorCode, extendedData));
  }
}
