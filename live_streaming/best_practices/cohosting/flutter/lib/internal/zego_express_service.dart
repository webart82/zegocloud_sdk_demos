import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/define.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'zego_express_service_event.dart';

export 'zego_service_define.dart';

class ZegoExpressService with ZegoExpressServiceEvent {
  ZegoExpressService._internal();
  static final ZegoExpressService shared = ZegoExpressService._internal();

  String room = '';
  ZegoUserInfo? localUser;
  List<ZegoUserInfo> userInfoList = [];
  Map<String, String> streamMap = {};

  StreamController<ZegoRoomUserListUpdateEvent> roomUserListUpdateStreamCtrl =
      StreamController<ZegoRoomUserListUpdateEvent>.broadcast();
  StreamController<ZegoRoomStreamListUpdateEvent> streamListUpdateStreamCtrl =
      StreamController<ZegoRoomStreamListUpdateEvent>.broadcast();
  StreamController<ZegoRoomCustomCommandEvent> customCommandStreamCtrl =
      StreamController<ZegoRoomCustomCommandEvent>.broadcast();
  StreamController<ZegoRoomStreamExtraInfoEvent> roomStreamExtraInfoStreamCtrl =
      StreamController<ZegoRoomStreamExtraInfoEvent>.broadcast();

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

  ZegoUserInfo? getUserInfo(String userID) {
    for (var user in userInfoList) {
      if (user.userID == userID) {
        return user;
      }
    }
    return null;
  }

  Future<ZegoRoomLoginResult> joinRoom(String roomID) async {
    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(localUser?.userID ?? '', localUser?.userName ?? ''),
      config: ZegoRoomConfig(0, true, ''),
    );
    if (joinRoomResult.errorCode == 0) {
      room = roomID;
    }
    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> leaveRoom() async {
    stopPreview();
    room = '';
    userInfoList.clear();
    resertLocalUser();
    streamMap.clear();
    final leaveResult = await ZegoExpressEngine.instance.logoutRoom();
    return leaveResult;
  }

  void resertLocalUser(){
    localUser?.streamID = null;
    localUser?.isCamerOnNoti.value = false;
    localUser?.isMicOnNoti.value = false;
    localUser?.canvasNoti.value = null;
    localUser?.viewID = -1;
    localUser?.roleNoti.value = ZegoLiveRole.audience;
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
    localUser?.isCamerOnNoti.value = isOn;
    final extraInfo = jsonEncode({
      'mic': localUser?.isMicOnNoti.value ?? false ? 'on' : 'off',
      'cam': isOn ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.enableCamera(isOn);
  }

  void turnMicrophoneOn(bool isOn) {
    localUser?.isMicOnNoti.value = isOn;
    final extraInfo = jsonEncode({
      'mic': isOn ? 'on' : 'off',
      'cam': localUser?.isCamerOnNoti.value ?? false ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.muteMicrophone(!isOn);
  }

  Future<void> startPlayingStream(String streamID) async {
    String? userID = streamMap[streamID];
    ZegoUserInfo? userInfo = getUserInfo(userID ?? '');
    if (userInfo != null) {
      userInfo.canvasNoti.value =
          await ZegoExpressEngine.instance.createCanvasView((viewID) => {
                userInfo.viewID = viewID,
              });
      ZegoCanvas canvas =
          ZegoCanvas(userInfo.viewID, viewMode: ZegoViewMode.AspectFill);
      await ZegoExpressEngine.instance
          .startPlayingStream(streamID, canvas: canvas);
    }
  }

  Future<void> stopPlayingStream(String streamID) async {
    String? userID = streamMap[streamID];
    ZegoUserInfo? userInfo = getUserInfo(userID ?? '');
    if (userInfo != null) {
      userInfo.streamID = '';
      userInfo.canvasNoti.value = null;
      userInfo.viewID = -1;
    }
    await ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }

  Future<void> startPreview() async {
    if (localUser != null) {
      localUser!.canvasNoti.value =
          await ZegoExpressEngine.instance.createCanvasView((viewID) => {
                localUser!.viewID = viewID,
              });

      final previewCanvas = ZegoCanvas(
        localUser!.viewID,
        viewMode: ZegoViewMode.AspectFill,
      );
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    }
  }

  Future<void> stopPreview() async {
    localUser?.canvasNoti.value = null;
    localUser?.viewID = -1;
    await ZegoExpressEngine.instance.stopPreview();
  }

  Future<void> startPublishingStream(String streamID) async {
    localUser?.streamID = streamID;
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> stopPublishingStream() async {
    localUser?.streamID = null;
    localUser?.isCamerOnNoti.value = false;
    localUser?.isMicOnNoti.value = false;
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

  //MARK: - Express Listen
  Future<void> onRoomStreamUpdate(String roomID, ZegoUpdateType updateType,
      List<ZegoStream> streamList, Map<String, dynamic> extendedData) async {
    for (ZegoStream stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        streamMap[stream.streamID] = stream.user.userID;
        ZegoUserInfo? userInfo = getUserInfo(stream.user.userID);
        if (userInfo == null) {
          userInfo = ZegoUserInfo(
              userID: stream.user.userID, userName: stream.user.userName);
          userInfoList.add(userInfo);
        }
        userInfo.streamID = stream.streamID;
        Map<String, dynamic> extraInfoMap =
            convert.jsonDecode(stream.extraInfo);
        bool isMicOn = (extraInfoMap['mic'] == 'on') ? true : false;
        bool isCameraOn = (extraInfoMap['cam'] == 'on') ? true : false;
        userInfo.isCamerOnNoti.value = isCameraOn;
        userInfo.isMicOnNoti.value = isMicOn;
        startPlayingStream(stream.streamID);
      } else {
        streamMap[stream.streamID] = '';
        ZegoUserInfo? userInfo = getUserInfo(stream.user.userID);
        userInfo?.streamID = '';
        userInfo?.isCamerOnNoti.value = false;
        userInfo?.isMicOnNoti.value = false;
        stopPlayingStream(stream.streamID);
      }
    }
    streamListUpdateStreamCtrl.add(ZegoRoomStreamListUpdateEvent(
        roomID, updateType, streamList, extendedData));
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
    roomUserListUpdateStreamCtrl
        .add(ZegoRoomUserListUpdateEvent(roomID, updateType, userList));
  }

  void onIMRecvCustomCommand(String roomID, ZegoUser fromUser, String command) {
    customCommandStreamCtrl
        .add(ZegoRoomCustomCommandEvent(roomID, fromUser, command));
  }

  void onRoomStreamExtraInfoUpdate(String roomID, List<ZegoStream> streamList) {
    for (var user in userInfoList) {
      for (ZegoStream stream in streamList) {
        if (stream.streamID == user.streamID) {
          Map<String, dynamic> extraInfoMap =
              convert.jsonDecode(stream.extraInfo);
          bool isMicOn = (extraInfoMap['mic'] == 'on') ? true : false;
          bool isCameraOn = (extraInfoMap['cam'] == 'on') ? true : false;
          user.isCamerOnNoti.value = isCameraOn;
          user.isMicOnNoti.value = isMicOn;
        }
      }
    }
    roomStreamExtraInfoStreamCtrl
        .add(ZegoRoomStreamExtraInfoEvent(roomID, streamList));
  }
}
