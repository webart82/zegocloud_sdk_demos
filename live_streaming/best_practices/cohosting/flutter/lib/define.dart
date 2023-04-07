import 'package:flutter/cupertino.dart';

class CustomCommandActionType{
    // audience
    static const int AudienceApplyToBecomeCoHost      = 10000;
    static const int AudienceCancelCoHostApply        = 10001;
    static const int HostRefuseAudienceCoHostApply    = 10002;
    static const int HostAcceptAudienceCoHostApply    = 10003;
    // host
    static const int HostInviteAudienceToBecomeCoHost = 10100;
    static const int HostCancelCoHostInvitation       = 10101;
    static const int AudienceRefuseCoHostInvitation   = 10102;
    static const int AudienceAcceptCoHostInvitation   = 10103;
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