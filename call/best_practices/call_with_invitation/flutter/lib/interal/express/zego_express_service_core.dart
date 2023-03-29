import 'dart:async';

import 'package:call_with_invitation/interal/express/zego_express_service_defines.dart';
import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoExpressServiceCore {
  StreamController<ZegoCameraStateChangeEvent> cameraStateUpdateStreamCtrl =
      StreamController<ZegoCameraStateChangeEvent>.broadcast();
  StreamController<ZegoMicrophoneStateChangeEvent>
      microphoneStateUpdateStreamCtrl =
      StreamController<ZegoMicrophoneStateChangeEvent>.broadcast();
  StreamController<ZegoRoomUserListUpdateEvent> roomUserListUpdateStreamCtrl =
      StreamController<ZegoRoomUserListUpdateEvent>.broadcast();
  StreamController<ZegoRoomStreamListUpdateEvent> streamListUpdateStreamCtrl =
      StreamController<ZegoRoomStreamListUpdateEvent>.broadcast();

  ZegoUserInfo localUser = ZegoUserInfo(userID: '', userName: '');
  String room = '';

  ValueNotifier<Widget?> localVideoView = ValueNotifier<Widget?>(null);
  int localViewID = 0;
  ValueNotifier<Widget?> remoteVideoView = ValueNotifier<Widget?>(null);
  int remoteViewID = 0;

  ZegoUserInfo connectUser(String id, String name) {
    localUser
      ..userID = id
      ..userName = name;

    return localUser;
  }

  void logout() {
    localUser
      ..userID = ''
      ..userName = '';
  }

  Future<void> startPreview() async {
    localVideoView.value = await ZegoExpressEngine.instance.createCanvasView((viewID) => {
          localViewID = viewID,
        });

    final previewCanvas = ZegoCanvas(
      localViewID,
      viewMode: ZegoViewMode.AspectFill,
    );

    ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
  }

  Future<void> stopPreview() async {
    localVideoView.value = null;
    localViewID = 0;
    ZegoExpressEngine.instance.stopPreview();
  }


  Future<void> startPublishingStream() async {
    String streamID = "${room}_${localUser.userID}"; 
    ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> stopPublishingStream() async {
    ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<void> startPlayingStream(String streamID) async {
    remoteVideoView.value = await ZegoExpressEngine.instance.createCanvasView((viewID) => {
      remoteViewID = viewID,
    });
    ZegoCanvas canvas = ZegoCanvas(remoteViewID,viewMode: ZegoViewMode.AspectFill);
    ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
  }

  void stopPlayingStream(String streamID) {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }

  //MARK: - Express Listen
  Future<void> onRoomStreamUpdate(String roomID, ZegoUpdateType updateType,
      List<ZegoStream> streamList, Map<String, dynamic> extendedData) async {
    streamListUpdateStreamCtrl.add(ZegoRoomStreamListUpdateEvent(
        roomID, updateType, streamList, extendedData));
  }

  void onRoomUserUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoUser> userList,
  ) {
    roomUserListUpdateStreamCtrl
        .add(ZegoRoomUserListUpdateEvent(roomID, updateType, userList));
  }

  void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    cameraStateUpdateStreamCtrl.add(ZegoCameraStateChangeEvent(state));
  }

  void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    microphoneStateUpdateStreamCtrl.add(ZegoMicrophoneStateChangeEvent(state));
  }

  void onRoomStateChanged(String roomID, ZegoRoomStateChangedReason reason,
      int errorCode, Map<String, dynamic> extendedData) {}
}
