import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/pages/pages.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_key_center.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';

import '../utils/permission.dart';

class ZegoLoginPage extends StatefulWidget {
  const ZegoLoginPage({super.key, required this.title});

  final String title;

  @override
  State<ZegoLoginPage> createState() => _ZegoLoginPageState();
}

class _ZegoLoginPageState extends State<ZegoLoginPage> {
  final userIDController = TextEditingController();
  final userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // init SDK
    ZegoSDKManager.shared.init(SDKKeyCenter.appID, SDKKeyCenter.appSign);
    requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
        child: Column(
          children: [
            userIDInputView(),
            const SizedBox(
              height: 20,
            ),
            userNameInputView(),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 200,
              height: 40,
              child: OutlinedButton(
                onPressed: () {
                  ZegoSDKManager.shared.connectUser(userIDController.text, userNameController.text).then((value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  });
                },
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userIDInputView() {
    return Row(
      children: [
        const SizedBox(width: 20),
        const Text('userID:'),
        const SizedBox(width: 10),
        Flexible(
            child: TextField(
          controller: userIDController,
          decoration: const InputDecoration(
            labelText: 'please input your userID',
          ),
        )),
      ],
    );
  }

  Widget userNameInputView() {
    return Row(
      children: [
        const SizedBox(width: 20),
        const Text('userName:'),
        const SizedBox(width: 10),
        Flexible(
            child: TextField(
          controller: userNameController,
          decoration: const InputDecoration(
            labelText: 'please input your userName',
          ),
        )),
      ],
    );
  }
}
