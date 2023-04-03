// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:flutter/material.dart';
import 'utils/permission.dart';
import 'home_page.dart';
import 'package:call_with_invitation/zego_sdk_key_center.dart';

void jumpToHomePage(
  BuildContext context, {
  required String localUserID,
  required String localUserName,
}) async {
  await ZEGOSDKManager.instance.init(appID, appSign);
  await ZEGOSDKManager.instance.connectUser(localUserID, localUserID);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MyHomePage(
        localUserID: localUserID,
        localUserName: localUserName,
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  /// Users who use the same roomID can join the same live streaming.
  final userIDTextCtrl = TextEditingController(text: Random().nextInt(100000).toString());
  final userNameTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();
    userNameTextCtrl.text = 'user_${userIDTextCtrl.text}';
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      fixedSize: const Size(120, 60),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please test with two or more devices'),
            const Divider(),
            TextFormField(
              controller: userIDTextCtrl,
              decoration: const InputDecoration(labelText: 'your userID'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: userNameTextCtrl,
              decoration: const InputDecoration(labelText: 'your userName'),
            ),
            const SizedBox(height: 20),
            // click me to navigate to CallPage
            ElevatedButton(
              style: buttonStyle,
              child: const Text('Login'),
              onPressed: () => jumpToHomePage(
                context,
                localUserID: userIDTextCtrl.text,
                localUserName: userNameTextCtrl.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
