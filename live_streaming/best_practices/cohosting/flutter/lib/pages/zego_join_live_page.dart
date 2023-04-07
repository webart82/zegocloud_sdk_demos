import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/define.dart';
import 'package:live_streaming_with_cohosting/pages/zego_live_page.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';

class ZegoJoinLivePage extends StatefulWidget {
  const ZegoJoinLivePage({super.key});

  @override
  State<ZegoJoinLivePage> createState() => _ZegoJoinLivePageState();
}

class _ZegoJoinLivePageState extends State<ZegoJoinLivePage> {
  final liveIDController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Live Room Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 100, left: 30, right: 30),
        child: Column(
          children: [
            liveIDTextField(),
            const SizedBox(
              height: 20,
            ),
            hostJoinLivePageButton(),
            const SizedBox(
              height: 20,
            ),
            audienceJoinLivePageButton(),
          ],
        ),
      ),
    );
  }

  Widget liveIDTextField() {
    return SizedBox(
      width: 350,
      height: 40,
      child: Row(
        children: [
          const Text('LiveID:'),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: TextField(
              controller: liveIDController,
              decoration: const InputDecoration(
                labelText: 'please input liveID',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget hostJoinLivePageButton() {
    return SizedBox(
      width: 200,
      height: 30,
      child: OutlinedButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ZegoLivePage(
                          liveID: liveIDController.text,
                          role: ZegoLiveRole.host,
                        )));
          },
          child: const Text('host Join Live')),
    );
  }

  Widget audienceJoinLivePageButton() {
    return SizedBox(
      width: 200,
      height: 30,
      child: OutlinedButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ZegoLivePage(
                          liveID: liveIDController.text,
                          role: ZegoLiveRole.audience,
                        )));
          },
          child: const Text('audience Join Live')),
    );
  }
}
