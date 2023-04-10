import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/pages/zego_page_define.dart';
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

  void pushToJoinLivePage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const ZegoJoinLivePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 100, left: 20, right: 20),
        child: Column(
          children: [
            userIDInputView(),
            SizedBox(
              height: 20,
            ),
            userNameInputView(),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 200,
              height: 40,
              child: OutlinedButton(
                  onPressed: () {
                    ZegoSDKManager.shared.connectUser(
                        userIDController.text, userNameController.text);
                    pushToJoinLivePage();
                  },
                  child: Text('Login')),
            ),
          ],
        ),
      ),
    );
  }

  Widget userIDInputView() {
    return Row(
      children: [
        SizedBox(width: 20),
        Text('userID:'),
        SizedBox(
          width: 10,
        ),
        Flexible(
            child: TextField(
          controller: userIDController,
          decoration: InputDecoration(
            labelText: 'please input your userID',
          ),
        )),
      ],
    );
  }

  Widget userNameInputView() {
    return Row(
      children: [
        SizedBox(width: 20),
        Text('userName:'),
        SizedBox(
          width: 10,
        ),
        Flexible(
            child: TextField(
          controller: userNameController,
          decoration: InputDecoration(
            labelText: 'please input your userName',
          ),
        )),
      ],
    );
  }
}
