import 'package:call_with_invitation/interal/im/zim_service.dart';
import 'package:zego_zim/zego_zim.dart';

mixin ZIMServiceEvent {

  void uninitEventHandle() {
    ZIMEventHandler.onCallInvitationRejected = null;
    ZIMEventHandler.onCallInvitationAccepted = null;
    ZIMEventHandler.onCallInvitationRejected = null;
    ZIMEventHandler.onCallInvitationCancelled = null;
    ZIMEventHandler.onCallInvitationTimeout = null;
    ZIMEventHandler.onCallInviteesAnsweredTimeout = null;
    ZIMEventHandler.onConnectionStateChanged = null;
  }

  void initEventHandle() {
    ZIMEventHandler.onCallInvitationReceived =(zim, info, callID) => ZIMService.shared.onCallInvitationReceived(zim, info, callID);
    ZIMEventHandler.onCallInvitationAccepted =(zim, info, callID) => ZIMService.shared.onCallInvitationAccepted(zim, info, callID);
    ZIMEventHandler.onCallInvitationCancelled =(zim, info, callID) => ZIMService.shared.onCallInvitationCancelled(zim, info, callID);
    ZIMEventHandler.onCallInvitationRejected =(zim, info, callID) => ZIMService.shared.onCallInvitationRejected(zim, info, callID);
    ZIMEventHandler.onCallInvitationTimeout =(zim, callID) => ZIMService.shared.onCallInvitationTimeout(zim, callID);
    ZIMEventHandler.onCallInviteesAnsweredTimeout =(zim, invitees, callID) => ZIMService.shared.onCallInviteesAnsweredTimeout(zim, invitees, callID);
    ZIMEventHandler.onConnectionStateChanged =(zim, state, event, extendedData) => ZIMService.shared.onConnectionStateChanged(zim, state, event, extendedData);
  }
}