import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/components/zego_audio_video_view.dart';
import 'package:live_streaming_with_cohosting/components/zego_live_bottom_bar.dart';
import 'package:live_streaming_with_cohosting/internal/zego_express_service.dart';
import 'package:live_streaming_with_cohosting/utils/flutter_extension.dart';
import 'package:live_streaming_with_cohosting/zego_sdk_manager.dart';

const double kButtonSize = 30;

class ZegoLivePage extends StatefulWidget {
  const ZegoLivePage({super.key, required this.roomID, required this.role});

  final String roomID;
  final ZegoLiveRole role;

  @override
  State<ZegoLivePage> createState() => _ZegoLivePageState();
}

class _ZegoLivePageState extends State<ZegoLivePage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];

  ValueNotifier<String?> hostStreamNotifier = ValueNotifier(null);
  ListNotifier<String> cohostStreamNotifier = ListNotifier([]);
  ValueNotifier<bool> isLivingNotifier = ValueNotifier(false);
  ListNotifier<String> applyCohostList = ListNotifier([]);
  ValueNotifier<bool> applyState = ValueNotifier(false);
  ValueNotifier<ZegoUserInfo?> hostUserInfoNotifier = ValueNotifier(null);

  bool showingDialog = false;

  @override
  void initState() {
    super.initState();

    subscriptions.addAll([
      ZegoSDKManager.shared.expressService.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate),
      ZegoSDKManager.shared.expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate),
      ZegoSDKManager.shared.expressService.customCommandStreamCtrl.stream.listen(onCustomCommandReceive),
      ZegoSDKManager.shared.expressService.roomStateChangedStreamCtrl.stream.listen(onRoomStateChanged),
    ]);

    if (widget.role == ZegoLiveRole.audience) {
      //Join room
      ZegoSDKManager.shared.localUser?.roleNotifier.value = ZegoLiveRole.audience;
      ZegoSDKManager.shared.expressService.joinRoom(widget.roomID).then(
        (value) {
          if (value.errorCode != 0) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
          }
        },
      );
    } else if (widget.role == ZegoLiveRole.host) {
      hostUserInfoNotifier.value = ZegoSDKManager.shared.localUser;
      ZegoSDKManager.shared.localUser?.roleNotifier.value = ZegoLiveRole.host;
      ZegoSDKManager.shared.expressService.turnCameraOn(true);
      ZegoSDKManager.shared.expressService.turnMicrophoneOn(true);
      ZegoSDKManager.shared.expressService.startPreview();
    }
  }

  @override
  void dispose() {
    super.dispose();
    ZegoSDKManager.shared.expressService.leaveRoom();
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
  }

  @override
  Widget build(Object context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLivingNotifier,
      builder: (context, isLiveing, _) {
        return Scaffold(
          body: Stack(
            children: [
              backgroundImage(),
              hostVideoView(),
              coHostVideoView(),
              if (!isLiveing && widget.role == ZegoLiveRole.host) startLiveButton(),
              hostText(),
              leaveButton(),
              if (isLiveing) bottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget bottomBar() {
    return LayoutBuilder(
      builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
          child: ZegoLiveBottomBar(
            cohostStreamNotifier: cohostStreamNotifier,
            applyState: applyState,
          ),
        );
      },
    );
  }

  Widget backgroundImage() {
    return LayoutBuilder(
      builder: (context, containers) {
        return SizedBox(
          width: containers.maxWidth,
          height: containers.maxHeight,
          child: Image.asset('assets/icons/bg.png', fit: BoxFit.fill),
        );
      },
    );
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

  Widget coHostVideoView() {
    return Positioned(
      right: 20,
      top: 100,
      child: Builder(builder: (context) {
        var height = (MediaQuery.of(context).size.height - kButtonSize - 100) / 4;
        var width = height * (9 / 16);

        return ValueListenableBuilder<List<String>>(
          valueListenable: cohostStreamNotifier,
          builder: (context, cohostList, _) {
            final videoList = getCoHostList(cohostList).map((user) {
              return ZegoAudioVideoView(userInfo: user);
            }).toList();

            return SizedBox(
              width: width,
              height: (MediaQuery.of(context).size.height - kButtonSize - 150),
              child: ListView.separated(
                reverse: true,
                itemCount: videoList.length,
                itemBuilder: (context, index) {
                  return SizedBox(width: width, height: height, child: videoList[index]);
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
              ),
            );
          },
        );
      }),
    );
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
    return LayoutBuilder(
      builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(top: containers.maxHeight - 110, left: (containers.maxWidth - 100) / 2),
          child: SizedBox(
            width: 100,
            height: 40,
            child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(width: 1, color: Colors.white)),
                onPressed: startLive,
                child: const Text(
                  'Start Live',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                )),
          ),
        );
      },
    );
  }

  void startLive() {
    isLivingNotifier.value = true;
    ZegoSDKManager.shared.expressService.joinRoom(widget.roomID).then(
      (value) {
        if (value.errorCode != 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
        } else {
          final userID = ZegoSDKManager.shared.localUser?.userID;
          final hostStreamID = '${widget.roomID}_${userID}_host';
          ZegoSDKManager.shared.expressService.startPublishingStream(hostStreamID);
        }
      },
    );
  }

  Widget leaveButton() {
    return LayoutBuilder(
      builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(left: containers.maxWidth - 60, top: 40),
          child: CircleAvatar(
            radius: kButtonSize / 2,
            backgroundColor: Colors.black26,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Image.asset('assets/icons/nav_close.png'),
            ),
          ),
        );
      },
    );
  }

  Widget hostText() {
    return ValueListenableBuilder<ZegoUserInfo?>(
      valueListenable: hostUserInfoNotifier,
      builder: (context, userInfo, _) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, top: 50),
          child: Text(
            'RoomID: ${widget.roomID}\n'
            'HostID: ${userInfo?.userName ?? ''}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        );
      },
    );
  }

  void onRoomStateChanged(ZegoRoomStateEvent event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1000),
        content: Text('room state changed: reason:${event.reason.name}, errorCode:${event.errorCode}'),
      ),
    );
  }

  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    for (var stream in event.streamList) {
      if (event.updateType == ZegoUpdateType.Add) {
        if (stream.streamID.endsWith('_host')) {
          isLivingNotifier.value = true;
          hostStreamNotifier.value = stream.streamID;
          hostUserInfoNotifier.value = ZegoUserInfo(userID: stream.user.userID, userName: stream.user.userName);
        } else if (stream.streamID.endsWith('_cohost')) {
          cohostStreamNotifier.add(stream.streamID);
        }
      } else {
        if (stream.streamID.endsWith('_host')) {
          isLivingNotifier.value = false;
          hostStreamNotifier.value = null;
          hostUserInfoNotifier.value = null;
        } else if (stream.streamID.endsWith('_cohost')) {
          cohostStreamNotifier.remove(stream.streamID);
        }
      }
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    for (var user in event.userList) {
      if (event.updateType == ZegoUpdateType.Delete) {
        if (cohostStreamNotifier.value.contains(user.userID)) {
          cohostStreamNotifier.remove(user.userID);
        }
        if (hostUserInfoNotifier.value?.userID == user.userID) {
          hostUserInfoNotifier.value = null;
        }
      }
    }
  }

  void onCustomCommandReceive(ZegoRoomCustomCommandEvent event) {
    Map<String, dynamic> commandMap = convert.jsonDecode(event.command);
    String userID = commandMap['userID'];
    if (commandMap['type'] == CustomCommandActionType.audienceApplyToBecomeCoHost) {
      applyCohostList.add(userID);
      // show dialog
      if (ZegoSDKManager.shared.getUser(userID) != null) {
        showApplyCohostDialog(ZegoSDKManager.shared.getUser(userID)!);
      }
    } else if (commandMap['type'] == CustomCommandActionType.audienceCancelCoHostApply) {
      applyCohostList.removeWhere((element) {
        return element == commandMap['userID'];
      });
      dismisApplyCohostDialog();
    } else if (commandMap['type'] == CustomCommandActionType.hostAcceptAudienceCoHostApply) {
      applyState.value = false;
      applyCohostList.removeWhere((element) {
        return element == commandMap['userID'];
      });
      becomeCoHost();
    } else if (commandMap['type'] == CustomCommandActionType.hostRefuseAudienceCoHostApply) {
      applyState.value = false;
      applyCohostList.removeWhere((element) {
        return element == commandMap['userID'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('host refuse your apply'),
        ),
      );
    }
  }

  void becomeCoHost() {
    final roomID = ZegoSDKManager.shared.expressService.room;
    final userID = ZegoSDKManager.shared.localUser!.userID;
    final cohostStreamID = '${roomID}_${userID}_cohost';
    ZegoSDKManager.shared.expressService.turnCameraOn(true);
    ZegoSDKManager.shared.expressService.turnMicrophoneOn(true);
    ZegoSDKManager.shared.expressService.startPreview();
    ZegoSDKManager.shared.expressService.localUser!.roleNotifier.value = ZegoLiveRole.coHost;
    ZegoSDKManager.shared.expressService.startPublishingStream(cohostStreamID);
    cohostStreamNotifier.add(cohostStreamID);
  }

  void dismisApplyCohostDialog() {
    if (showingDialog) {
      Navigator.of(context).pop();
      showingDialog = false;
    }
  }

  void showApplyCohostDialog(ZegoUserInfo userInfo) {
    if (showingDialog) {
      return;
    }
    showingDialog = true;
    showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('apply become cohost'),
          content: Text('${userInfo.userName} apply become cohost'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Refuse'),
              onPressed: () {
                final command = jsonEncode({
                  'type': CustomCommandActionType.hostRefuseAudienceCoHostApply,
                  'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
                });
                ZegoSDKManager.shared.expressService.sendCommandMessage(command, [userInfo.userID]).then((value) {
                  if (value.errorCode != 0) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('refuse cohost failed: ${value.errorCode}')));
                  }
                  Navigator.pop(context);
                });
              },
            ),
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                final command = jsonEncode({
                  'type': CustomCommandActionType.hostAcceptAudienceCoHostApply,
                  'userID': ZegoSDKManager.shared.localUser?.userID ?? '',
                });
                ZegoSDKManager.shared.expressService.sendCommandMessage(command, [userInfo.userID]).then((value) {
                  if (value.errorCode != 0) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('accept apply cohost failed: ${value.errorCode}')));
                  }
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    ).whenComplete(() => showingDialog = false);
  }
}
