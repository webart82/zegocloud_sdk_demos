import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/define.dart';
import 'package:live_streaming_with_cohosting/pages/zego_live_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final roomIDController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 100, left: 30, right: 30),
        child: Column(
          children: [
            roomIDTextField(),
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

  Widget roomIDTextField() {
    return SizedBox(
      width: 350,
      height: 40,
      child: Row(
        children: [
          const Text('RoomID:'),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: TextField(
              controller: roomIDController,
              decoration: const InputDecoration(
                labelText: 'please input roomID',
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
                          roomID: roomIDController.text,
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
                          roomID: roomIDController.text,
                          role: ZegoLiveRole.audience,
                        )));
          },
          child: const Text('audience Join Live')),
    );
  }
}
