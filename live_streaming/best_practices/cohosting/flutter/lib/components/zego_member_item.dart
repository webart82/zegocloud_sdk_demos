import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/internal/zego_express_service.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../define.dart';

class ZegoMemberItem extends StatefulWidget {
  const ZegoMemberItem(
      {required this.userInfo, required this.applyCohostList, super.key});

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
                SizedBox(
                  width: 40,
                ),
                OutlinedButton(
                    onPressed: () {
                      final command = jsonEncode({
                        'type': CustomCommandActionType
                            .HostRefuseAudienceCoHostApply,
                        'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
                      });
                      ZegoSDKManager.shared.expressService.sendCommandMessage(
                          command, [widget.userInfo.userID]);
                      widget.applyCohostList.value.removeWhere((element) {
                        return element == widget.userInfo.userID;
                      });
                    },
                    child: Text('Disagree')),
                SizedBox(
                  width: 10,
                ),
                OutlinedButton(
                    onPressed: () {
                      final command = jsonEncode({
                        'type': CustomCommandActionType
                            .HostAcceptAudienceCoHostApply,
                        'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
                      });
                      ZegoSDKManager.shared.expressService.sendCommandMessage(
                          command, [widget.userInfo.userID]);
                      widget.applyCohostList.value.removeWhere((element) {
                        return element == widget.userInfo.userID;
                      });
                    },
                    child: Text('Agree')),
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
