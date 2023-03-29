import 'dart:async';
import 'dart:ffi';

import 'package:call_with_invitation/interal/im/zim_service_defines.dart';

import 'zego_express_service_event.dart';
import 'zego_express_service_core.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoExpressService with ZegoExpressServiceEvent {
  ZegoExpressService._internal();

  static final ZegoExpressService shared = ZegoExpressService._internal();

  ZegoExpressServiceCore core = ZegoExpressServiceCore();

  bool isInit = false;

  Future<void> init({
    required int appID,
    String appSign = '',
    ZegoScenario scenario = ZegoScenario.Default,
  }) async {
    isInit = true;

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
    core.connectUser(id, name);
  }

  Future<ZegoRoomLoginResult> joinRoom(String roomID) async {
    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(core.localUser.userID, core.localUser.userName),
      config: ZegoRoomConfig(0, true, ''),
    );
    if (joinRoomResult.errorCode == 0) {
      core.room = roomID;
    }
    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> leaveRoom() async {
    final leaveResult = await ZegoExpressEngine.instance.logoutRoom();
    if (leaveResult.errorCode == 0) {
      core.room = '';
      core.localVideoView.value = null;
      core.remoteVideoView.value = null;
      core.stopPreview();
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
    await core.startPlayingStream(streamID);
  }

  void stopPlayingStream(String streamID) async {
    core.stopPlayingStream(streamID);
  }
}
