import 'dart:convert';
import 'package:flutter/material.dart';
import 'call/waiting_page.dart';
import 'utils/permission.dart';
import 'dart:async';
import 'call/calling_page.dart';
import 'interal/zim/zim_service_defines.dart';
import 'zego_sdk_manager.dart';
import 'zego_user_Info.dart';
import 'components/zego_call_invitation_dialog.dart';
import 'interal/zim/call_data_manager.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.localUserID, required this.localUserName}) : super(key: key);

  final String localUserID;
  final String localUserName;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  final myController = TextEditingController();

  bool dialogIsShowing = false;

  @override
  void initState() {
    super.initState();
    requestPermission();
    subscriptions.addAll([
      ZEGOSDKManager.instance.zimService.receiveCallStreamCtrl.stream.listen(onReceiveCall),
      ZEGOSDKManager.instance.zimService.cancelCallStreamCtrl.stream.listen(onCancelCall)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zego Call Invitation Demo'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your userID: ${widget.localUserID}'),
              const SizedBox(height: 20),
              Text('Your userName: ${widget.localUserName}'),
              const SizedBox(height: 20),
              const Divider(),
              const Text('make a direct call:'),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: myController,
                    decoration: const InputDecoration(labelText: 'input invitee userID'),
                  )),
                  ElevatedButton(
                    onPressed: () => startCall(ZegoCallType.voice),
                    child: const ImageIcon(AssetImage('assets/icons/voice_call_normal.png')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => startCall(ZegoCallType.video),
                    child: const ImageIcon(AssetImage('assets/icons/video_call_normal.png')),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> startCall(ZegoCallType callType) async {
    final extendedData = jsonEncode({
      'type': callType.index, //video_call
      'inviterName': widget.localUserName,
    });

    final ZegoSendInvitationResult result = await ZEGOSDKManager.instance
        .sendInvitation(invitees: [myController.text], callType: callType, extendedData: extendedData);

    if (result.error == null || result.error?.code == '0') {
      if (result.errorInvitees.containsKey(myController.text)) {
        ZegoCallDataManager.instance.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('user is not online: $result')),
        );
      } else {
        ZegoCallDataManager.instance.createCall(
          result.invitationID,
          ZegoUserInfo(userID: widget.localUserID, userName: widget.localUserName),
          ZegoUserInfo(userID: myController.text, userName: ''),
          ZegoCallUserState.inviting,
          callType,
        );
        pushToCallWaitingPage();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('send call invitation failed: $result')),
      );
    }
  }

  void onReceiveCall(ZIMReveiveCallEvent event) {
    Map<String, dynamic> extendedDataMap = jsonDecode(event.extendedData);
    ZegoCallType type = extendedDataMap['type'] == ZegoCallType.video.index ? ZegoCallType.video : ZegoCallType.voice;
    String inviterName = extendedDataMap['inviterName'] as String;
    // show call dialog
    dialogIsShowing = true;
    showTopModalSheet(
      context,
      GestureDetector(
        onTap: onInvitationTopSheetEmptyClicked,
        child: ZegoCallInvitationDialog(
          invitationData: ZegoCallData(
              inviter: ZegoUserInfo(userID: event.inviter, userName: inviterName),
              invitee: ZegoUserInfo(userID: widget.localUserID, userName: widget.localUserName),
              callType: type,
              callID: event.callID),
          onAcceptCallback: acceptCall,
          onRefuseCallback: () {
            ZEGOSDKManager.instance.zimService.refuseInvitation(invitationID: event.callID);
            hideInvitationTopSheet();
          },
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> acceptCall() async {
    hideInvitationTopSheet();
    ZegoResponseInvitationResult result = await ZEGOSDKManager.instance.zimService
        .acceptInvitation(invitationID: ZegoCallDataManager.instance.callData?.callID ?? '');
    if (result.error == null || result.error?.code == '0') {
      pushToCallingPage();
    }
  }

  Future<T?> showTopModalSheet<T>(BuildContext context, Widget widget, {bool barrierDismissible = true}) {
    return showGeneralDialog<T?>(
      context: context,
      barrierDismissible: barrierDismissible,
      transitionDuration: const Duration(milliseconds: 250),
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, _, __) => SafeArea(
          child: Column(
        children: [
          const SizedBox(height: 16),
          widget,
        ],
      )),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
              .drive(Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)),
          child: child,
        );
      },
    );
  }

  void onInvitationTopSheetEmptyClicked() {
    hideInvitationTopSheet();
    pushToCallWaitingPage();
  }

  void hideInvitationTopSheet() {
    if (dialogIsShowing) {
      dialogIsShowing = false;
      Navigator.of(context).pop();
    }
  }

  void onCancelCall(ZIMCancelCallEvent event) {
    // remote call dialog
    hideInvitationTopSheet();
  }

  void pushToCallWaitingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CallWaitingPage(callData: ZegoCallDataManager.instance.callData),
      ),
    );
  }

  void pushToCallingPage() {
    if (ZegoCallDataManager.instance.callData != null) {
      ZegoUserInfo otherUser;
      if (ZegoCallDataManager.instance.callData!.inviter.userID != ZEGOSDKManager.instance.localUser.userID) {
        otherUser = ZegoCallDataManager.instance.callData!.inviter;
      } else {
        otherUser = ZegoCallDataManager.instance.callData!.invitee;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CallingPage(callData: ZegoCallDataManager.instance.callData!, otherUserInfo: otherUser),
        ),
      );
    }
  }
}
