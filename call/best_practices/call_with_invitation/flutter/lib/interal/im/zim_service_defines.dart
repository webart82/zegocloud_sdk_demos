import 'package:flutter/services.dart';
import 'package:zego_zim/zego_zim.dart';
import 'zim_service_enum.dart';

class ZegoSendInvitationResult {
  const ZegoSendInvitationResult({
    this.error,
    required this.invitationID,
    required this.errorInvitees,
  });

  final PlatformException? error;
  final String invitationID;
  final Map<String, ZegoCallUserState> errorInvitees;

  @override
  String toString() => '{error: $error, '
      'invitationID: $invitationID, '
      'errorInvitees: $errorInvitees}';
}

class ZegoCancelInvitationResult {
  const ZegoCancelInvitationResult({
    this.error,
    required this.errorInvitees,
  });

  final PlatformException? error;
  final List<String> errorInvitees;

  @override
  String toString() => '{error: $error, '
      'errorInvitees: $errorInvitees}';
}

class ZegoResponseInvitationResult {
  const ZegoResponseInvitationResult({
    this.error,
  });

  final PlatformException? error;

  @override
  String toString() => '{error: $error}';
}

class ZegoJoinRoomResult {
  const ZegoJoinRoomResult({
    this.error,
  });

  final PlatformException? error;

  @override
  String toString() => '{error: $error}';
}

class ZegoLeaveRoomResult {
  const ZegoLeaveRoomResult({
    this.error,
  });

  final PlatformException? error;

  @override
  String toString() => '{error: $error}';
}

class ZIMReveiveCallEvent {
  final String inviter;
  final String extendedData;
  final String callID;

  ZIMReveiveCallEvent(this.callID, this.inviter, this.extendedData);
}

class ZIMAcceptCallEvent {
  final String invitee;
  final String extendedData;
  final String callID;

  ZIMAcceptCallEvent(this.callID, this.invitee, this.extendedData);
}

class ZIMCancelCallEvent {
  final String inviter;
  final String extendedData;
  final String callID;

  ZIMCancelCallEvent(this.callID, this.inviter, this.extendedData);
}

class ZIMRejectCallEvent {
  final String invitee;
  final String extendedData;
  final String callID;

  ZIMRejectCallEvent(this.callID, this.invitee, this.extendedData);
}

class ZIMTimeOutCallEvent {
  final String callID;

  ZIMTimeOutCallEvent(this.callID);
}

class ZIMAnswerTimeOutCallEvent {

  final String callID;
  final List<String> invitees;

  ZIMAnswerTimeOutCallEvent(this.callID, this.invitees);
}

class ZIMConnectionStateChangeEvent {

  final ZIMConnectionState state;
  final ZIMConnectionEvent event;

  ZIMConnectionStateChangeEvent(this.state, this.event);
}
