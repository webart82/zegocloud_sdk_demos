import 'dart:async';
import 'dart:math';
import 'dart:convert' as covert;
import 'package:call_with_invitation/call/CallWaitPage.dart';
import 'package:call_with_invitation/call/CallingPage.dart';
import 'package:call_with_invitation/interal/im/zim_service_defines.dart';
import 'package:call_with_invitation/interal/im/zim_service_enum.dart';
import 'package:call_with_invitation/zego_sdk_key_center.dart';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:call_with_invitation/zego_user_Info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'components/zego_call_invitation_dialog.dart';
import 'interal/im/zim_service_call_data_manager.dart';

final myUserID = generateRandomString(6);
final myUserName = 'user_{$myUserID}';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Call Invitation Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  final myController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ZegoSDKManager.shared.init(SDKKeyCenter.appID, SDKKeyCenter.appSign);
    ZegoSDKManager.shared.connectUser(myUserID, myUserName);
    subscriptions
      ..add(ZegoSDKManager.shared.zimService.receiveCallStreamCtrl.stream
          .listen(onReceiveCall))
      ..add(ZegoSDKManager.shared.zimService.cancelCallStreamCtrl.stream
          .listen(onCancelCall));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text('my userID:$myUserID'),
            const Padding(padding: EdgeInsets.only(top: 20)),
            const Text('make a direct call:'),
            const Padding(padding: EdgeInsets.only(top: 20)),
            Row(
              children: <Widget>[
                Flexible(
                    child: TextField(
                  controller: myController,
                  decoration: InputDecoration(
                    labelText: 'input invitee userID',
                  ),
                )),
                IconButton(
                    onPressed: startVoiceCall,
                    icon: const ImageIcon(
                        AssetImage('assets/icons/voice_call_normal.png'))),
                IconButton(
                    onPressed: startVideoCall,
                    icon: const ImageIcon(
                        AssetImage('assets/icons/video_call_normal.png'))),
              ],
            )
          ],
        ),
      ),
    );
  }

  void onReceiveCall(ZIMReveiveCallEvent event) {
    Map<String, dynamic> extendedDataMap =
        covert.jsonDecode(event.extendedData);
    ZegoCallType type = (extendedDataMap['type'] as String) == '1'
        ? ZegoCallType.video
        : ZegoCallType.voice;
    String inviterName = extendedDataMap['inviterName'] as String;
    // show call dialog
    showTopModalSheet(
      context,
      GestureDetector(
        onTap: onInvitationTopSheetEmptyClicked,
        child: ZegoCallInvitationDialog(
          invitationData: ZegoCallData(
              inviter:
                  ZegoUserInfo(userID: event.inviter, userName: inviterName),
              invitee: ZegoUserInfo(userID: myUserID, userName: myUserName),
              callType: type,
              callID: event.callID),
          onAcceptCallback: () {},
          onRefuseCallback: () {},
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<T?> showTopModalSheet<T>(BuildContext context, Widget widget,
      {bool barrierDismissible = true}) {
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
          position:
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                  .drive(Tween<Offset>(
                      begin: const Offset(0, -1.0), end: Offset.zero)),
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
    Navigator.of(context).pop();
  }

  void onCancelCall(ZIMCancelCallEvent event) {
    // remote call dialog
    hideInvitationTopSheet();
  }

  Future<void> startVoiceCall() async {
    String extendedData = '{"type": "0", "inviterName": "$myUserName"}';
    final ZegoSendInvitationResult result = await ZegoSDKManager.shared
        .sendInvitation(
            invitees: [myController.text],callType: ZegoCallType.voice,
            extendedData: extendedData); // send call invitation
    if (result.error == null || result.error?.code == '0') {
      final ZegoRoomLoginResult loginResult = await ZegoSDKManager.shared
          .joinRoom(result.invitationID); // join express room
      if (loginResult.errorCode == 0) {
        if (result.errorInvitees.containsValue(myController.text)) {
          //user is not noline
          return;
        }
        pushToCallWaitingPage();
      } else {
        // join room fail
      }
    } else {
      // send call invitation fail
    }
  }

  Future<void> startVideoCall() async {
    String extendedData = '{"type": "1", "inviterName": "$myUserName"}';
    final ZegoSendInvitationResult result = await ZegoSDKManager.shared
        .sendInvitation(
            invitees: [myController.text], callType: ZegoCallType.video,extendedData: extendedData);
    if (result.error == null || result.error?.code == '0') {
      if (result.errorInvitees.keys.contains(myController.text)) {
        //user is not noline
        ZegoCallDataManager.shared.clear();
        return;
      }
      final ZegoRoomLoginResult loginResult = await ZegoSDKManager.shared
          .joinRoom(result.invitationID); // join express room
      if (loginResult.errorCode == 0) {
        pushToCallWaitingPage();
      } else {
        // join room fail
      }
    } else {
      // show error
    }
  }

  void pushToCallWaitingPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) =>
                CallWaitPage(callData: ZegoCallDataManager.shared.callData)));
  }
}

String generateRandomString(int length) {
  final _random = Random();
  const _availableChars = '1234567890';
  final randomString = List.generate(length,
          (index) => _availableChars[_random.nextInt(_availableChars.length)])
      .join();
  return randomString;
}
