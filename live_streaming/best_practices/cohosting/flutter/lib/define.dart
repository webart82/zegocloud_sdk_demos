import 'package:flutter/cupertino.dart';

class CustomCommandActionType {
  // audience
  static const int audienceApplyToBecomeCoHost = 10000;
  static const int audienceCancelCoHostApply = 10001;
  static const int hostRefuseAudienceCoHostApply = 10002;
  static const int hostAcceptAudienceCoHostApply = 10003;
  // host
}

enum ZegoLiveRole {
  audience,
  host,
  coHost,
}

class ButtonIcon {
  Widget? icon;
  Color? backgroundColor;

  ButtonIcon({this.icon, this.backgroundColor});
}
