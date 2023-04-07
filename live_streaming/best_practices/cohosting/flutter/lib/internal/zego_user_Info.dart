import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/define.dart';

class ZegoUserInfo {
  
  ZegoUserInfo({
    required this.userID,
    required this.userName,
  });

  late String userID;
  late String userName;

  ValueNotifier<ZegoLiveRole> roleNoti = ValueNotifier(ZegoLiveRole.audience);
  String? streamID;
  int viewID = -1;
  ValueNotifier<Widget?>canvasNoti = ValueNotifier(null);
  ValueNotifier<bool> isCamerOnNoti = ValueNotifier(false);
  ValueNotifier<bool> isMicOnNoti = ValueNotifier(false);
}