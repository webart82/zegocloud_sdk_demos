import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/components/zego_switch_camera_button.dart';
import 'package:live_streaming_with_cohosting/components/zego_toggle_camera_button.dart';
import 'package:live_streaming_with_cohosting/components/zego_toggle_microphone_button.dart';
import 'package:live_streaming_with_cohosting/define.dart';
import 'package:live_streaming_with_cohosting/utils/flutter_extension.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../internal/zego_user_info.dart';

class ZegoLiveBottomBar extends StatefulWidget {
  const ZegoLiveBottomBar({
    required this.cohostStreamNotifier,
    this.applyState,
    super.key,
  });

  final ValueNotifier<bool>? applyState;
  final ListNotifier<String> cohostStreamNotifier;

  @override
  State<ZegoLiveBottomBar> createState() => _ZegoLiveBottomBarState();
}

class _ZegoLiveBottomBarState extends State<ZegoLiveBottomBar> {
  bool isCameraOn = true;
  bool isMicOn = true;
  bool isFacingCamera = true;

  @override
  Widget build(BuildContext context) {
    if (ZegoSDKManager.shared.localUser == null) {
      return Container();
    } else {
      return ValueListenableBuilder<ZegoLiveRole>(
        valueListenable: ZegoSDKManager.shared.localUser!.roleNotifier,
        builder: (context, role, _) {
          return getBottomBar(role);
        },
      );
    }
  }

  Widget getBottomBar(ZegoLiveRole role) {
    return buttonView(role);
  }

  Widget buttonView(ZegoLiveRole role) {
    if (role == ZegoLiveRole.host) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          switchCameraButton(),
        ],
      );
    } else if (role == ZegoLiveRole.audience) {
      return ValueListenableBuilder<bool>(
        valueListenable: widget.applyState!,
        builder: (context, state, _) {
          return Container(
            alignment: Alignment.centerRight,
            child: state ? cancelApplyCohost() : applyCoHost(),
          );
        },
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          switchCameraButton(),
          endCohostButton(),
        ],
      );
    }
  }

  Widget toggleMicButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleMicrophoneButton(
          onPressed: () {
            isMicOn = !isMicOn;
            ZegoSDKManager.shared.expressService.turnMicrophoneOn(isMicOn);
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
            isCameraOn = !isCameraOn;
            ZegoSDKManager.shared.expressService.turnCameraOn(isCameraOn);
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
            ZegoSDKManager.shared.expressService.useFrontFacingCamera(isFacingCamera);
          },
        ),
      );
    });
  }

  Widget applyCoHost() {
    return SizedBox(
      width: 120,
      height: 40,
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(side: const BorderSide(width: 1, color: Colors.white)),
          onPressed: () {
            final command = jsonEncode({
              'type': CustomCommandActionType.audienceApplyToBecomeCoHost,
              'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
            });
            ZegoSDKManager.shared.expressService
                .sendCommandMessage(command, [getHostUser()?.userID ?? '']).then((value) {
              if (value.errorCode != 0) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('apply cohost failed: ${value.errorCode}')));
              } else {
                widget.applyState?.value = true;
              }
            });
          },
          child: const Text(
            'applyCohost',
            style: TextStyle(color: Colors.white),
          )),
    );
  }

  Widget cancelApplyCohost() {
    return SizedBox(
      width: 120,
      height: 40,
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(side: const BorderSide(width: 1, color: Colors.white)),
          onPressed: () {
            final command = jsonEncode({
              'type': CustomCommandActionType.audienceCancelCoHostApply,
              'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
            });
            ZegoSDKManager.shared.expressService
                .sendCommandMessage(command, [getHostUser()?.userID ?? '']).then((value) {
              if (value.errorCode != 0) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('cancel apply cohost failed: ${value.errorCode}')));
              } else {
                widget.applyState?.value = false;
              }
            });
          },
          child: const Text(
            'cancelApplyCohost',
            style: TextStyle(color: Colors.white),
          )),
    );
  }

  ZegoUserInfo? getHostUser() {
    if (ZegoSDKManager.shared.localUser?.roleNotifier.value == ZegoLiveRole.host) {
      return ZegoSDKManager.shared.localUser;
    } else {
      for (var userInfo in ZegoSDKManager.shared.expressService.userInfoList) {
        if (userInfo.streamID != null) {
          if (userInfo.streamID!.endsWith('_host')) {
            return userInfo;
          }
        }
      }
    }
    return null;
  }

  Widget endCohostButton() {
    return SizedBox(
      width: 120,
      height: 40,
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(side: const BorderSide(width: 1, color: Colors.white)),
          onPressed: () {
            widget.cohostStreamNotifier.removeWhere((element) {
              return element == ZegoSDKManager.shared.localUser!.streamID;
            });
            ZegoSDKManager.shared.expressService.stopPreview();
            ZegoSDKManager.shared.localUser?.roleNotifier.value = ZegoLiveRole.audience;
            ZegoSDKManager.shared.expressService.stopPublishingStream();
          },
          child: const Text(
            'end cohost',
            style: TextStyle(
              color: Colors.white,
            ),
          )),
    );
  }
}
