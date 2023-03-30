import 'dart:async';
import 'dart:math';
import 'package:call_with_invitation/call/CallingPage.dart';
import 'package:call_with_invitation/components/zego_accept_button.dart';
import 'package:call_with_invitation/components/zego_cancel_button.dart';
import 'package:call_with_invitation/components/zego_defines.dart';
import 'package:call_with_invitation/components/zego_refuse_button.dart';
import 'package:call_with_invitation/interal/im/zim_service_call_data_manager.dart';
import 'package:call_with_invitation/interal/im/zim_service_enum.dart';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../interal/im/zim_service_defines.dart';
import '../zego_user_Info.dart';

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
      ..add(ZegoSDKManager.shared.zimService.rejectCallStreamCtrl.stream
          .listen(onRejectCall))
      ..add(ZegoSDKManager.shared.zimService.acceptCallStreamCtrl.stream
          .listen(onAcceptCall))
      ..add(ZegoSDKManager.shared.zimService.cancelCallStreamCtrl.stream
          .listen(onCancelCall));

    ZegoSDKManager.shared.expressService.core.startPreview();
  }

  void onRejectCall(ZIMRejectCallEvent event) {
    Navigator.pop(context);
  }

  Future<void> onAcceptCall(ZIMAcceptCallEvent event) async {
    //show calling page
    if (widget.callData != null) {
      pushToCallingPage();
    }
  }

  void onCancelCall(ZIMCancelCallEvent event) {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
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
    if (widget.callData?.inviter.userID ==
        ZegoSDKManager.shared.localUser.userID) {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(
              left: 0, right: 0, top: containers.maxHeight - 70),
          child: Container(
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
    return ValueListenableBuilder<Widget?>(
        valueListenable: ZegoSDKManager.shared.getVideoViewNotifier(null),
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
          icon: ButtonIcon(
            icon: (widget.callData!.callType == ZegoCallType.video)
                ? Image(image: AssetImage('assets/icons/invite_video.png'))
                : Image(image: AssetImage('assets/icons/invite_voice.png')),
          ),
          onPressed: acceptCall,
        ),
      );
    });
  }

  Future<void> acceptCall() async {
    final ZegoResponseInvitationResult result = await ZegoSDKManager.shared
        .acceptInvitation(invitationID: widget.callData?.callID ?? '');
    if (result.error == null || result.error?.code == '0') {
      // join room
      final ZegoRoomLoginResult joinRoomResult =
          await ZegoSDKManager.shared.joinRoom(widget.callData?.callID ?? '');
      if (joinRoomResult.errorCode == 0) {
        pushToCallingPage();
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

  void pushToCallingPage() {
    ZegoSDKManager.shared.expressService.core.stopPreview();
    if (ZegoCallDataManager.shared.callData != null) {
      ZegoUserInfo otherUser;
      if (ZegoCallDataManager.shared.callData!.inviter.userID !=
          ZegoSDKManager.shared.localUser.userID) {
        otherUser = ZegoCallDataManager.shared.callData!.inviter;
      } else {
        otherUser = ZegoCallDataManager.shared.callData!.invitee;
      }
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => CallingPage(
                  callData: ZegoCallDataManager.shared.callData!,
                  otherUserInfo: otherUser)));
    }
  }
}
