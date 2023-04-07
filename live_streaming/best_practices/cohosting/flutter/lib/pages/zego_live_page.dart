import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/components/zego_audio_video_view.dart';
import 'package:live_streaming_with_cohosting/components/zego_live_bottom_bar.dart';
import 'package:live_streaming_with_cohosting/define.dart';
import 'package:live_streaming_with_cohosting/internal/zego_express_service.dart';
import 'package:live_streaming_with_cohosting/utils/flutter_extension.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoLivePage extends StatefulWidget {
  const ZegoLivePage({super.key, required this.liveID, required this.role});

  final String liveID;
  final ZegoLiveRole role;

  @override
  State<ZegoLivePage> createState() => _ZegoLivePageState();
}

class _ZegoLivePageState extends State<ZegoLivePage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];

  // ValueNotifier<List<ZegoUserInfo>> coHostListNoti = ValueNotifier([]);
  ValueNotifier<String?> hostStreamNoti = ValueNotifier(null);
  ListNotifier<String> coHostStreamNoti = ListNotifier([]);
  ValueNotifier<bool> isLivingNoti = ValueNotifier(false);
  ListNotifier<String> applyCohostList = ListNotifier([]);
  ValueNotifier<bool> applyState = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    subscriptions
      ..add(ZegoSDKManager
          .shared.expressService.streamListUpdateStreamCtrl.stream
          .listen(onStreamListUpdate))
      ..add(ZegoSDKManager
          .shared.expressService.roomUserListUpdateStreamCtrl.stream
          .listen(onRoomUserListUpdate))
      ..add(ZegoSDKManager.shared.expressService.customCommandStreamCtrl.stream
          .listen(onCustomCommandReceive));

    if (widget.role == ZegoLiveRole.audience) {
      //Join room
      ZegoSDKManager.shared.localUser?.roleNoti.value = ZegoLiveRole.audience;
      ZegoSDKManager.shared.joinRoom(widget.liveID);
    } else if (widget.role == ZegoLiveRole.host) {
      ZegoSDKManager.shared.localUser?.roleNoti.value = ZegoLiveRole.host;
      ZegoSDKManager.shared.expressService.turnCameraOn(true);
      ZegoSDKManager.shared.expressService.turnMicrophoneOn(true);
      ZegoSDKManager.shared.expressService.startPreview();
    } else {}
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
  }

  @override
  Widget build(Object context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isLivingNoti,
        builder: (context, isLiveing, _) {
          return Scaffold(
            body: Stack(
              children: [
                backgroundImage(),
                hostVideoView(),
                coHostView(),
                if (!isLiveing && widget.role == ZegoLiveRole.host)
                  startLiveButton(),
                hostText(),
                leaveButton(),
                if (isLiveing) bottomBarView(),
              ],
            ),
          );
        });
  }

  Widget bottomBarView() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding:
            EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
        child: ZegoLiveBottomBar(
          coHostStreamNoti: coHostStreamNoti,
          applyState: applyState,
        ),
      );
    });
  }

  Widget backgroundImage() {
    return LayoutBuilder(builder: (context, containers) {
      return Container(
        width: containers.maxWidth,
        height: containers.maxHeight,
        child: Image.asset(
          'assets/icons/bg.png',
          fit: BoxFit.fill,
        ),
      );
    });
  }

  Widget hostVideoView() {
    ZegoUserInfo? hostUser = getHostUser();
    if (hostUser == null) {
      return Container();
    }
    return ZegoAudioVideoView(userInfo: hostUser);
  }

  ZegoUserInfo? getHostUser() {
    if (widget.role == ZegoLiveRole.host) {
      return ZegoSDKManager.shared.localUser;
    } else {
      for (var userInfo in ZegoSDKManager.shared.expressService.userInfoList) {
        if (userInfo.streamID != null) {
          if (userInfo.streamID!.endsWith('_host')) {
            return userInfo;
          }
        }
      }
    }
    return null;
  }

  Widget coHostView() {
    return Positioned(
      right: 20,
      top: 100,
      width: 96,
      height: 600,
      child: coHostVideoView(),
    );
  }

  Widget coHostVideoView() {
    return ValueListenableBuilder<List<String>>(
        valueListenable: coHostStreamNoti,
        builder: (context, cohostList, _) {
          var videoList = <Widget>[];
          for (var user in getCoHostList(cohostList)) {
            ZegoAudioVideoView videoView = ZegoAudioVideoView(userInfo: user);
            videoList.add(videoView);
          }
          return Column(
            children: [
              for (Widget view in videoList) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 96,
                  height: 164,
                  child: view,
                )
              ],
            ],
          );
        });
  }

  List<ZegoUserInfo> getCoHostList(List<String> cohost) {
    List<ZegoUserInfo> list = [];
    for (var streamID in cohost) {
      if (streamID == ZegoSDKManager.shared.localUser?.streamID) {
        list.add(ZegoSDKManager.shared.localUser!);
      } else {
        for (var user in ZegoSDKManager.shared.expressService.userInfoList) {
          if (user.streamID != null && streamID == user.streamID) {
            list.add(user);
          }
        }
      }
    }
    return list;
  }

  Widget startLiveButton() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding: EdgeInsets.only(
            top: containers.maxHeight - 110,
            left: (containers.maxWidth - 100) / 2),
        child: SizedBox(
          width: 100,
          height: 40,
          child:
              OutlinedButton(onPressed: startLive, child: Text('Start Live')),
        ),
      );
    });
  }

  Future<void> startLive() async {
    var userID = ZegoSDKManager.shared.localUser?.userID;
    var hostStreamID = '${widget.liveID}_${userID}_host';
    isLivingNoti.value = true;
    await ZegoSDKManager.shared.joinRoom(widget.liveID);
    ZegoSDKManager.shared.expressService.startPublishingStream(hostStreamID);
  }

  Widget leaveButton() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding: EdgeInsets.only(left: containers.maxWidth - 60, top: 40),
        child: Container(
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black12,
            child: IconButton(
                onPressed: () {
                  ZegoSDKManager.shared.expressService.leaveRoom();
                  Navigator.pop(context);
                },
                icon: Image.asset('assets/icons/nav_close.png')),
          ),
        ),
      );
    });
  }

  Widget memberButton() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding:
            EdgeInsets.only(left: containers.maxWidth - 60 - 100 - 40, top: 40),
        child: OutlinedButton(
            onPressed: () {
              // showModalBottomSheet(
              //   barrierColor: Colors.red,
              //   backgroundColor: Colors.black,
              //   context: context,
              //   shape: const RoundedRectangleBorder(
              //     borderRadius: BorderRadius.only(
              //       topLeft: Radius.circular(32.0),
              //       topRight: Radius.circular(32.0),
              //     ),
              //   ),
              //   isDismissible: true,
              //   isScrollControlled: true,
              //   builder: (BuildContext context) {
              //     return FractionallySizedBox(
              //       heightFactor: 0.85,
              //       child: AnimatedPadding(
              //         padding: MediaQuery.of(context).viewInsets,
              //         duration: const Duration(milliseconds: 50),
              //         child: Container(
              //           padding: const EdgeInsets.symmetric(
              //               vertical: 0, horizontal: 10),
              //           child: getMembersListView(),
              //         ),
              //       ),
              //     );
              //   },
              // );
            },
            child: Text('showMembers')),
      );
    });
  }

  Widget getMembersListView() {
    return ListView.builder(
        itemCount: getMemberItems().length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              height: 50,
              child: Text(
                'Members',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          } else {
            return getMemberItems()[index - 1];
          }
        });
  }

  List<Widget> getMemberItems() {
    List<Widget> items = [];
    if (ZegoSDKManager.shared.localUser != null) {
      items.add(memberItem(ZegoSDKManager.shared.localUser!));
    }
    for (var user in ZegoSDKManager.shared.expressService.userInfoList) {
      items.add(memberItem(user));
    }
    return items;
  }

  Widget memberItem(ZegoUserInfo userInfo) {
    return Container(
      height: 40,
      color: Colors.blue,
      child: Row(
        children: [
          Text('userName:'),
        ],
      ),
    );
  }

  Widget hostText() {
    return Padding(
      padding: EdgeInsets.only(left: 20, top: 40),
      child: Text('hostName'),
    );
  }

  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    for (var stream in event.streamList) {
      if (event.updateType == ZegoUpdateType.Add) {
        if (stream.streamID.endsWith('_host')) {
          isLivingNoti.value = true;
          hostStreamNoti.value = stream.streamID;
        } else if (stream.streamID.endsWith('_cohost')) {
          coHostStreamNoti.add(stream.streamID);
        }
      } else {
        if (stream.streamID.endsWith('_host')) {
          isLivingNoti.value = false;
          hostStreamNoti.value = null;
        } else if (stream.streamID.endsWith('_cohost')) {
          coHostStreamNoti.remove(stream.streamID);
        }
      }
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    for (var user in event.userList) {
      if (event.updateType == ZegoUpdateType.Delete) {
        //if (user.userID == widget.otherUserInfo.userID) {
        // ZegoCallDataManager.shared.clear();
        // ZegoSDKManager.shared.expressService.leaveRoom();
        // Navigator.pop(context);
        //}
      }
    }
  }

  void onCustomCommandReceive(ZegoRoomCustomCommandEvent event) {
    Map<String, dynamic> commandMap = convert.jsonDecode(event.command);
    String userID = commandMap['userID'];
    if (commandMap['type'] ==
        CustomCommandActionType.AudienceApplyToBecomeCoHost) {
      applyCohostList.add(userID);
      // show dialog
      if (ZegoSDKManager.shared.getUser(userID) != null) {
        showApplyCohostDialog(ZegoSDKManager.shared.getUser(userID)!);
      }
    } else if (commandMap['type'] ==
        CustomCommandActionType.AudienceAcceptCoHostInvitation) {
      applyCohostList.removeWhere((element) {
        return element == commandMap['userID'];
      });
    } else if (commandMap['type'] ==
        CustomCommandActionType.AudienceCancelCoHostApply) {
      applyCohostList.removeWhere((element) {
        return element == commandMap['userID'];
      });
    } else if (commandMap['type'] ==
        CustomCommandActionType.HostAcceptAudienceCoHostApply) {
      applyState.value = false;
      applyCohostList.removeWhere((element) {
        return element == commandMap['userID'];
      });
      becomeCoHost();
    } else if (commandMap['type'] ==
        CustomCommandActionType.AudienceRefuseCoHostInvitation) {
    } else if (commandMap['type'] ==
        CustomCommandActionType.HostCancelCoHostInvitation) {
    } else if (commandMap['type'] ==
        CustomCommandActionType.HostInviteAudienceToBecomeCoHost) {
      if (commandMap['userID'] == ZegoSDKManager.shared.localUser?.userID) {
        // show dialog
        showInviteDialog();
      }
    } else if (commandMap['type'] ==
        CustomCommandActionType.HostRefuseAudienceCoHostApply) {
      applyState.value = false;
      applyCohostList.removeWhere((element) {
        return element == commandMap['userID'];
      });
    }
  }

  void becomeCoHost() {
    ZegoSDKManager.shared.expressService.turnCameraOn(true);
    ZegoSDKManager.shared.expressService.turnMicrophoneOn(true);
    ZegoSDKManager.shared.expressService.startPreview();
    String cohostStreamID =
        '${ZegoSDKManager.shared.expressService.room}_${ZegoSDKManager.shared.localUser?.userID ?? ''}_cohost';
    ZegoSDKManager.shared.expressService.localUser?.streamID = cohostStreamID;
    ZegoSDKManager.shared.expressService.localUser?.roleNoti.value =
        ZegoLiveRole.coHost;
    ZegoSDKManager.shared.expressService.startPublishingStream(cohostStreamID);
    coHostStreamNoti.add(cohostStreamID);
  }

  void showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('host invite your cohost'),
          content: Text('host invite your cohost'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showApplyCohostDialog(ZegoUserInfo userInfo) {
    showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('apply become cohost'),
          content: Text('${userInfo.userName} apply become cohost'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                final command = jsonEncode({
                  'type': CustomCommandActionType.HostRefuseAudienceCoHostApply,
                  'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
                });
                ZegoSDKManager.shared.expressService
                    .sendCommandMessage(command, [userInfo.userID]);
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                final command = jsonEncode({
                  'type': CustomCommandActionType.HostAcceptAudienceCoHostApply,
                  'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
                });
                ZegoSDKManager.shared.expressService
                    .sendCommandMessage(command, [userInfo.userID]);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
