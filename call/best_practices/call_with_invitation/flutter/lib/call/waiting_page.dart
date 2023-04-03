import 'dart:async';
import 'package:call_with_invitation/call/calling_page.dart';
import 'package:call_with_invitation/components/zego_accept_button.dart';
import 'package:call_with_invitation/components/zego_cancel_button.dart';
import 'package:call_with_invitation/components/zego_defines.dart';
import 'package:call_with_invitation/components/zego_refuse_button.dart';
import 'package:call_with_invitation/interal/zim/zim_service_call_data_manager.dart';
import 'package:call_with_invitation/interal/zim/zim_service_enum.dart';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:flutter/material.dart';

import '../interal/zim/zim_service_defines.dart';
import '../zego_user_Info.dart';

class CallWaitingPage extends StatefulWidget {
  const CallWaitingPage({this.callData, super.key});

  final ZegoCallData? callData;

  @override
  State<CallWaitingPage> createState() => _CallWaitingPageState();
}

class _CallWaitingPageState extends State<CallWaitingPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];

  @override
  void initState() {
    super.initState();

    subscriptions
      ..add(ZegoSDKManager.instance.zimService.rejectCallStreamCtrl.stream.listen(onRejectCall))
      ..add(ZegoSDKManager.instance.zimService.acceptCallStreamCtrl.stream.listen(onAcceptCall))
      ..add(ZegoSDKManager.instance.zimService.cancelCallStreamCtrl.stream.listen(onCancelCall));

    if (widget.callData?.callType == ZegoCallType.video) {
      ZegoSDKManager.instance.expressService.core.startPreview();
    }
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
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: (widget.callData?.callType == ZegoCallType.video)
                ? [
                    videoView(),
                    buttonView(),
                  ]
                : [buttonView()],
          ),
        ),
      ),
    );
  }

  Widget buttonView() {
    if (widget.callData?.inviter.userID == ZegoSDKManager.instance.localUser.userID) {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
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
          padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
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
        valueListenable: ZegoSDKManager.instance.getVideoViewNotifier(null),
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
    ZegoSDKManager.instance.cancelInvitation(
        invitationID: widget.callData?.callID ?? ' ', invitees: [widget.callData?.invitee.userID ?? '']);
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
                ? const Image(image: AssetImage('assets/icons/invite_video.png'))
                : const Image(image: AssetImage('assets/icons/invite_voice.png')),
          ),
          onPressed: acceptCall,
        ),
      );
    });
  }

  Future<void> acceptCall() async {
    final ZegoResponseInvitationResult result =
        await ZegoSDKManager.instance.acceptInvitation(invitationID: widget.callData?.callID ?? '');
    if (result.error == null || result.error?.code == '0') {
      pushToCallingPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('accept call invitation failed: $result')),
      );
    }
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
    await ZegoSDKManager.instance.refuseInvitation(invitationID: widget.callData?.callID ?? '');
    Navigator.pop(context);
  }

  void pushToCallingPage() {
    ZegoSDKManager.instance.expressService.core.stopPreview();
    if (ZegoCallDataManager.instance.callData != null) {
      ZegoUserInfo otherUser;
      if (ZegoCallDataManager.instance.callData!.inviter.userID != ZegoSDKManager.instance.localUser.userID) {
        otherUser = ZegoCallDataManager.instance.callData!.inviter;
      } else {
        otherUser = ZegoCallDataManager.instance.callData!.invitee;
      }
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  CallingPage(callData: ZegoCallDataManager.instance.callData!, otherUserInfo: otherUser)));
    }
  }
}
