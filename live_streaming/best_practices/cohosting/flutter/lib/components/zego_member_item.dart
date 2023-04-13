import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/internal/zego_express_service.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';

class ZegoMemberItem extends StatefulWidget {
  const ZegoMemberItem({required this.userInfo, required this.applyCohostList, super.key});

  final ZegoUserInfo userInfo;
  final ValueNotifier<List<String>> applyCohostList;

  @override
  State<ZegoMemberItem> createState() => _ZegoMemberItemState();
}

class _ZegoMemberItemState extends State<ZegoMemberItem> {
  @override
  Widget build(BuildContext context) {
    // return ValueListenableBuilder(valueListenable: widget.userInfo, builder: builder)
    return ValueListenableBuilder<List<String>>(
        valueListenable: widget.applyCohostList,
        builder: (context, applyCohosts, _) {
          if (applyCohosts.contains(widget.userInfo.userID)) {
            return Row(
              children: [
                Text(widget.userInfo.userName),
                const SizedBox(
                  width: 40,
                ),
                OutlinedButton(
                    onPressed: () {
                      final command = jsonEncode({
                        'type': CustomCommandActionType.hostRefuseAudienceCoHostApply,
                        'userID': ZEGOSDKManager.instance.localUser?.userID ?? '',
                      });
                      ZEGOSDKManager.instance.expressService.sendCommandMessage(command, [widget.userInfo.userID]);
                      widget.applyCohostList.value.removeWhere((element) {
                        return element == widget.userInfo.userID;
                      });
                    },
                    child: const Text('Disagree')),
                const SizedBox(
                  width: 10,
                ),
                OutlinedButton(
                    onPressed: () {
                      final command = jsonEncode({
                        'type': CustomCommandActionType.hostAcceptAudienceCoHostApply,
                        'userID': ZEGOSDKManager.instance.localUser?.userID ?? '',
                      });
                      ZEGOSDKManager.instance.expressService.sendCommandMessage(command, [widget.userInfo.userID]);
                      widget.applyCohostList.value.removeWhere((element) {
                        return element == widget.userInfo.userID;
                      });
                    },
                    child: const Text('Agree')),
              ],
            );
          } else {
            return Container(
              child: Text(widget.userInfo.userName),
            );
          }
        });
  }
}
