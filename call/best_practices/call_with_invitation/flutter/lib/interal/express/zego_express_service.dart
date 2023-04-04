import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../zego_user_Info.dart';

import 'package:zego_express_engine/zego_express_engine.dart';

import 'zego_express_service_defines.dart';

class ExpressService {
  ExpressService._internal();
  factory ExpressService() => instance;
  static final ExpressService instance = ExpressService._internal();

  ZegoUserInfo localUser = ZegoUserInfo(userID: '', userName: '');
  String currentRoomID = '';

  ValueNotifier<Widget?> localVideoView = ValueNotifier<Widget?>(null);
  int localViewID = 0;
  ValueNotifier<Widget?> remoteVideoView = ValueNotifier<Widget?>(null);
  int remoteViewID = 0;

  bool isInit = false;

  Future<void> init({
    required int appID,
    String appSign = '',
    ZegoScenario scenario = ZegoScenario.StandardVideoCall,
  }) async {
    isInit = true;
    initEventHandle();

    final profile = ZegoEngineProfile(appID, scenario, appSign: appSign);
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
    localUser
      ..userID = id
      ..userName = name;
  }

  Future<void> disConnectUser(String id, String name) async {
    localUser
      ..userID = ''
      ..userName = '';
  }

  Future<void> startPublishingStream() async {
    String streamID = "${currentRoomID}_${localUser.userID}";
    ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> stopPublishingStream() async {
    ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID) async {
    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(localUser.userID, localUser.userName),
      config: ZegoRoomConfig(0, true, ''),
    );
    if (joinRoomResult.errorCode == 0) {
      currentRoomID = roomID;
    }
    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> logoutRoom([String roomID = '']) async {
    if (roomID.isEmpty) roomID = currentRoomID;
    final leaveResult = await ZegoExpressEngine.instance.logoutRoom(roomID);
    if (leaveResult.errorCode == 0) {
      currentRoomID = '';
      localVideoView.value = null;
      remoteVideoView.value = null;
      localViewID = 0;
      await ZegoExpressEngine.instance.stopPreview();
    }
    return leaveResult;
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
    ZegoExpressEngine.instance.enableCamera(isOn);
  }

  void turnMicrophoneOn(bool isOn) {
    ZegoExpressEngine.instance.muteMicrophone(!isOn);
  }

  Future<void> startPlayingStream(String streamID) async {
    remoteVideoView.value = await ZegoExpressEngine.instance.createCanvasView((viewID) => {
          remoteViewID = viewID,
        });
    ZegoCanvas canvas = ZegoCanvas(remoteViewID, viewMode: ZegoViewMode.AspectFill);
    ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
  }

  void stopPlayingStream(String streamID) async {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }

  Future<void> startPreview() async {
    localVideoView.value = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      localViewID = viewID;
    });

    final previewCanvas = ZegoCanvas(
      localViewID,
      viewMode: ZegoViewMode.AspectFill,
    );

    await ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
  }

  Future<void> stopPreview() async {
    localVideoView.value = null;
    localViewID = 0;
    await ZegoExpressEngine.instance.stopPreview();
  }

  void uninitEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRemoteCameraStateUpdate = null;
    ZegoExpressEngine.onRemoteMicStateUpdate = null;
    ZegoExpressEngine.onRoomStateChanged = null;
  }

  void initEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = ExpressService.instance.onRoomStreamUpdate;
    ZegoExpressEngine.onRoomUserUpdate = ExpressService.instance.onRoomUserUpdate;
    ZegoExpressEngine.onRemoteCameraStateUpdate = ExpressService.instance.onRemoteCameraStateUpdate;
    ZegoExpressEngine.onRemoteMicStateUpdate = ExpressService.instance.onRemoteMicStateUpdate;
    ZegoExpressEngine.onRoomStateChanged = ExpressService.instance.onRoomStateChanged;
  }

  StreamController<ZegoCameraStateChangeEvent> cameraStateUpdateStreamCtrl =
      StreamController<ZegoCameraStateChangeEvent>.broadcast();
  StreamController<ZegoMicrophoneStateChangeEvent> microphoneStateUpdateStreamCtrl =
      StreamController<ZegoMicrophoneStateChangeEvent>.broadcast();
  StreamController<ZegoRoomUserListUpdateEvent> roomUserListUpdateStreamCtrl =
      StreamController<ZegoRoomUserListUpdateEvent>.broadcast();
  StreamController<ZegoRoomStreamListUpdateEvent> streamListUpdateStreamCtrl =
      StreamController<ZegoRoomStreamListUpdateEvent>.broadcast();

  Future<void> onRoomStreamUpdate(
      String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) async {
    for (ZegoStream stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        startPlayingStream(stream.streamID);
      } else {
        stopPlayingStream(stream.streamID);
      }
    }
    streamListUpdateStreamCtrl.add(ZegoRoomStreamListUpdateEvent(roomID, updateType, streamList, extendedData));
  }

  void onRoomUserUpdate(String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
    roomUserListUpdateStreamCtrl.add(ZegoRoomUserListUpdateEvent(roomID, updateType, userList));
  }

  void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    cameraStateUpdateStreamCtrl.add(ZegoCameraStateChangeEvent(state));
  }

  void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    microphoneStateUpdateStreamCtrl.add(ZegoMicrophoneStateChangeEvent(state));
  }

  void onRoomStateChanged(
      String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData) {}
}
