import 'dart:async';
import 'dart:math';
import 'package:call_with_invitation/components/zego_accept_button.dart';
import 'package:call_with_invitation/components/zego_cancel_button.dart';
import 'package:call_with_invitation/components/zego_refuse_button.dart';
import 'package:call_with_invitation/interal/im/zim_service_call_data_manager.dart';
import 'package:call_with_invitation/interal/im/zim_service_enum.dart';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../interal/im/zim_service_defines.dart';

class CallWaitPage extends StatefulWidget {
  const CallWaitPage({this.callData, super.key});

  final ZegoCallData? callData;

  @override
  State<CallWaitPage> createState() => _CallWaitPageState();
}

class _CallWaitPageState extends State<CallWaitPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];

  @override
  void initState() {
    super.initState();

    subscriptions
    ..add(ZegoSDKManager.shared.zimService.rejectCallStreamCtrl.stream.listen(onRejectCall))
    ..add(ZegoSDKManager.shared.zimService.acceptCallStreamCtrl.stream.listen(onAcceptCall))
    ..add(ZegoSDKManager.shared.zimService.cancelCallStreamCtrl.stream.listen(onCancelCall));
    
  }

  void onRejectCall(ZIMRejectCallEvent event) {
    Navigator.pop(context);
  }

  void onAcceptCall(ZIMAcceptCallEvent event) {
    //show calling page
    
  }

  void onCancelCall(ZIMCancelCallEvent event) {
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            videoView(),
            buttonView(),
          ],
        ),
      ),
    );
  }

  Widget buttonView() {
    if (widget.callData?.inviter.userID !=
        ZegoSDKManager.shared.localUser.userID) {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(
              left: 0, right: 0, top: containers.maxHeight - 70),
          child: Container(
            color: Colors.blue,
            padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                cancelCallButton(),
              ],
            ),
          ),
        );
      });
    } else {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(
              left: 0, right: 0, top: containers.maxHeight - 70),
          child: Container(
            color: Colors.blue,
            padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                declineCallButton(),
                acceptCallButton(),
              ],
            ),
          ),
        );
      });
    }
  }

  Widget videoView() {
    return Container(
      padding: const EdgeInsets.all(0),
      color: Colors.red,
    );
  }

  Widget cancelCallButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoCancelButton(
          onPressed: cancelCall,
        ),
      );
    });
  }

  Future<void> cancelCall() async {
    ZegoSDKManager.shared.cancelInvitation(
        invitationID: widget.callData?.callID ?? ' ',
        invitees: [widget.callData?.invitee.userID ?? '']);
    ZegoSDKManager.shared.expressService.leaveRoom();
    Navigator.pop(context);
  }

  Widget acceptCallButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoAcceptButton(
          onPressed: acceptCall,
        ),
      );
    });
  }

  Future<void> acceptCall() async {
    final ZegoResponseInvitationResult result = await ZegoSDKManager.shared
        .acceptInvitation(invitationID: widget.callData?.callID ?? '');
    if (result.error?.code == '0') {
      // join room
      final ZegoJoinRoomResult joinRoomResult = (await ZegoSDKManager.shared
          .joinRoom(widget.callData?.callID ?? '')) as ZegoJoinRoomResult;
      if (joinRoomResult.error?.code == '0') {

      }
    } else {}
  }

  Widget declineCallButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoRefuseButton(
          onPressed: declineCall,
        ),
      );
    });
  }

  Future<void> declineCall() async {
    await ZegoSDKManager.shared
        .refuseInvitation(invitationID: widget.callData?.callID ?? '');
    Navigator.pop(context);
  }
}
