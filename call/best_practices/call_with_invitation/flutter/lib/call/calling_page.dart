import 'dart:async';
import 'package:call_with_invitation/components/zego_cancel_button.dart';
import 'package:call_with_invitation/components/zego_speaker_button.dart';
import 'package:call_with_invitation/components/zego_switch_camera_button.dart';
import 'package:call_with_invitation/components/zego_toggle_camera_button.dart';
import 'package:call_with_invitation/components/zego_toggle_microphone_button.dart';
import 'package:call_with_invitation/interal/zim/zim_service_call_data_manager.dart';
import 'package:call_with_invitation/interal/zim/zim_service_enum.dart';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../interal/express/zego_express_service_defines.dart';

class CallingPage extends StatefulWidget {
  const CallingPage({required this.callData, required this.otherUserInfo, super.key});

  final ZegoCallData callData;
  final ZegoUserInfo otherUserInfo;

  @override
  State<CallingPage> createState() => _CallingPageState();
}

class _CallingPageState extends State<CallingPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<String> streamIDList = [];

  bool micIsOn = true;
  bool cameraIsOn = true;
  bool isFacingCamera = true;
  bool isSpeaker = true;

  @override
  void initState() {
    super.initState();

    subscriptions.addAll([
      ZegoSDKManager.instance.expressService.core.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate),
      ZegoSDKManager.instance.expressService.core.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate)
    ]);

    ZegoSDKManager.instance.expressService.joinRoom(widget.callData.callID).then((ZegoRoomLoginResult joinRoomResult) {
      if (joinRoomResult.errorCode == 0) {
        ZegoSDKManager.instance.expressService.core.startPublishingStream();
        ZegoSDKManager.instance.turnMicrophoneOn(micIsOn);
        ZegoSDKManager.instance.setAudioOutputToSpeaker(isSpeaker);
        if (widget.callData.callType == ZegoCallType.voice) {
          cameraIsOn = false;
          ZegoSDKManager.instance.turnCameraOn(cameraIsOn);
          ZegoSDKManager.instance.useFrontFacingCamera(isFacingCamera);
        } else {
          ZegoSDKManager.instance.expressService.turnCameraOn(cameraIsOn);
          ZegoSDKManager.instance.expressService.core.startPreview();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('join room fail: ${joinRoomResult.errorCode},${joinRoomResult.extendedData}')),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
    ZegoCallDataManager.instance.clear();
    for (String streamID in streamIDList) {
      ZegoSDKManager.instance.expressService.stopPlayingStream(streamID);
    }
    ZegoSDKManager.instance.expressService.core.stopPreview();
    ZegoSDKManager.instance.expressService.core.stopPublishingStream();
    ZegoSDKManager.instance.expressService.leaveRoom(widget.callData.callID);
    super.dispose();
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
        valueListenable: ZegoSDKManager.instance.getVideoViewNotifier(widget.otherUserInfo.userID),
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
          valueListenable: ZegoSDKManager.instance.getVideoViewNotifier(null),
          builder: (context, view, _) {
            if (view != null) {
              return Container(
                margin: EdgeInsets.only(top: 100, left: constraints.maxWidth - 95.0 - 20),
                width: 95.0,
                height: 164.0,
                child: view,
              );
            } else {
              return Container(
                margin: EdgeInsets.only(top: 100, left: constraints.maxWidth - 95.0 - 20),
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
        padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
        child: buttonView(),
      );
    });
  }

  Widget buttonView() {
    if (widget.callData.callType == ZegoCallType.voice) {
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
            micIsOn = !micIsOn;
            ZegoSDKManager.instance.turnMicrophoneOn(micIsOn);
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
            ZegoSDKManager.instance.turnCameraOn(cameraIsOn);
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
            ZegoSDKManager.instance.useFrontFacingCamera(isFacingCamera);
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
            ZegoSDKManager.instance.setAudioOutputToSpeaker(isSpeaker);
          },
        ),
      );
    });
  }

  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    for (var stream in event.streamList) {
      if (event.updateType == ZegoUpdateType.Add) {
        streamIDList.add(stream.streamID);
        ZegoSDKManager.instance.expressService.startPlayingStream(stream.streamID);
      } else {
        streamIDList.remove(stream.streamID);
        ZegoSDKManager.instance.expressService.stopPlayingStream(stream.streamID);
      }
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    for (var user in event.userList) {
      if (event.updateType == ZegoUpdateType.Delete) {
        if (user.userID == widget.otherUserInfo.userID) {
          Navigator.pop(context);
        }
      }
    }
  }
}