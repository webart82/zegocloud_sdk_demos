import 'dart:async';
import 'dart:math';
import 'package:call_with_invitation/components/zego_cancel_button.dart';
import 'package:call_with_invitation/components/zego_speaker_button.dart';
import 'package:call_with_invitation/components/zego_switch_camera_button.dart';
import 'package:call_with_invitation/components/zego_toggle_camera_button.dart';
import 'package:call_with_invitation/components/zego_toggle_microphone_button.dart';
import 'package:call_with_invitation/interal/im/zim_service_enum.dart';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../components/zego_accept_button.dart';
import '../interal/express/zego_express_service_defines.dart';

class CallingPage extends StatefulWidget {
  const CallingPage(
      {this.callType = ZegoCallType.voice, this.userInfo, super.key});

  final ZegoCallType callType;
  final ZegoUserInfo? userInfo;

  @override
  State<CallingPage> createState() => _CallingPageState();
}

class _CallingPageState extends State<CallingPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<String>streamIDList = [];

  bool micIsOn = true;
  bool cameraIsOn = true;
  bool isFacingCamera = true;
  bool isSpeaker = true;

  @override
  void initState() {
    super.initState();
    ZegoSDKManager.shared.turnMicrophoneOn(micIsOn);
    ZegoSDKManager.shared.setAudioOutputToSpeaker(isSpeaker);
    if (widget.callType == ZegoCallType.voice) {
      cameraIsOn = false;
      ZegoSDKManager.shared.turnCameraOn(cameraIsOn);
      ZegoSDKManager.shared.useFrontFacingCamera(isFacingCamera);
    } else {
      ZegoSDKManager.shared.expressService.turnCameraOn(cameraIsOn);
    }
    subscriptions
    ..add(ZegoSDKManager.shared.expressService.core.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate))
    ..add(ZegoSDKManager.shared.expressService.core.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate));
    // start publishing stream
    ZegoSDKManager.shared.expressService.core.startPublishingStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Stack(
        children: [
          largetVideoView(),
          smallVideoView(),
          bottomBar(),
        ],
      ),
    ));
  }

  Widget largetVideoView() {
    return ValueListenableBuilder<Widget?>(
        valueListenable:
            ZegoSDKManager.shared.getVideoViewNotifier(widget.userInfo?.userID),
        builder: (context, view, _) {
          if (view != null) {
            return view;
          } else {
            return Container(
              padding: const EdgeInsets.all(0),
              color: Colors.black,
            );
          }
        });
  }

  Widget smallVideoView() {
    return LayoutBuilder(builder: (context, constraints) {
      return ValueListenableBuilder<Widget?>(
          valueListenable: ZegoSDKManager.shared.getVideoViewNotifier(null),
          builder: (context, view, _) {
            if (view != null) {
              return view;
            } else {
              return Container(
                margin: EdgeInsets.only(
                    top: 100, left: constraints.maxWidth - 95.0 - 20),
                width: 95.0,
                height: 164.0,
                color: Colors.red,
              );
            }
          });
    });
  }

  Widget bottomBar() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding:
            EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
        child: buttonView(),
      );
    });
  }

  Widget buttonView() {
    if (widget.callType == ZegoCallType.voice) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          endCallButton(),
          speakerButton(),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          endCallButton(),
          speakerButton(),
          switchCameraButton(),
        ],
      );
    }
  }

  Widget endCallButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoCancelButton(
          onPressed: () {
            for (String streamID in streamIDList) {
              ZegoSDKManager.shared.expressService.stopPlayingStream(streamID);
            }
            ZegoSDKManager.shared.expressService.core.stopPreview();
            ZegoSDKManager.shared.expressService.core.stopPublishingStream();
            ZegoSDKManager.shared.expressService.leaveRoom();
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  Widget toggleMicButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleMicrophoneButton(
          onPressed: () {
            ZegoSDKManager.shared.turnMicrophoneOn(false);
          },
        ),
      );
    });
  }

  Widget toggleCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleCameraButton(
          onPressed: () {
            cameraIsOn = !cameraIsOn;
            ZegoSDKManager.shared.turnCameraOn(cameraIsOn);
          },
        ),
      );
    });
  }

  Widget switchCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoSwitchCameraButton(
          onPressed: () {
            isFacingCamera = !isFacingCamera;
            ZegoSDKManager.shared.useFrontFacingCamera(isFacingCamera);
          },
        ),
      );
    });
  }

  Widget speakerButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoSpeakerButton(
          onPressed: () {
            isSpeaker = !isSpeaker;
            ZegoSDKManager.shared.setAudioOutputToSpeaker(isSpeaker);
          },
        ),
      );
    });
  }

  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    for (var stream in event.streamList) {
      if (event.updateType == ZegoUpdateType.Add) {
        streamIDList.add(stream.streamID);
        ZegoSDKManager.shared.expressService.startPlayingStream(stream.streamID);
      } else {
        streamIDList.remove(stream.streamID);
        ZegoSDKManager.shared.expressService.stopPlayingStream(stream.streamID);
      }  
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    for (var user in event.userList) {
      if (event.updateType == ZegoUpdateType.Delete) {
        if (user.userID == widget.userInfo?.userID) {
          Navigator.pop(context);
        }
      }
    }
  }
}
