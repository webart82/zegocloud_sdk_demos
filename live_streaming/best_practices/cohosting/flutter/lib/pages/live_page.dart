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
  ValueNotifier<bool> applying = ValueNotifier(false);
  ValueNotifier<ZegoUserInfo?> hostUserInfoNotifier = ValueNotifier(null);

  bool showingDialog = false;

  @override
  void initState() {
    super.initState();

    subscriptions.addAll([
      ZEGOSDKManager.instance.expressService.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate),
      ZEGOSDKManager.instance.expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate),
      ZEGOSDKManager.instance.zimService.receiveRoomCustomSignalingStreamCtrl.stream
          .listen(onRoomCustomSignalingReceived),
      ZEGOSDKManager.instance.expressService.roomStateChangedStreamCtrl.stream.listen(onRoomStateChanged),
    ]);

    if (widget.role == ZegoLiveRole.audience) {
      //Join room
      ZEGOSDKManager.instance.localUser?.roleNotifier.value = ZegoLiveRole.audience;
      ZEGOSDKManager.instance.loginRoom(widget.roomID).then(
        (value) {
          if (value.errorCode != 0) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
          }
        },
      );
    } else if (widget.role == ZegoLiveRole.host) {
      hostUserInfoNotifier.value = ZEGOSDKManager.instance.localUser;
      ZEGOSDKManager.instance.localUser?.roleNotifier.value = ZegoLiveRole.host;
      ZEGOSDKManager.instance.expressService.turnCameraOn(true);
      ZEGOSDKManager.instance.expressService.turnMicrophoneOn(true);
      ZEGOSDKManager.instance.expressService.startPreview();
    }
  }

  @override
  void dispose() {
    super.dispose();
    ZEGOSDKManager.instance.expressService.stopPreview();
    ZEGOSDKManager.instance.logoutRoom();
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
          child: ZegoLiveBottomBar(cohostStreamNotifier: cohostStreamNotifier, applying: applying),
        );
      },
    );
  }

  Widget backgroundImage() {
    return Image.asset(
      'assets/icons/bg.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
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
      return ZEGOSDKManager.instance.localUser;
    } else {
      for (var userInfo in ZEGOSDKManager.instance.expressService.userInfoList) {
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
      if (streamID == ZEGOSDKManager.instance.localUser?.streamID) {
        list.add(ZEGOSDKManager.instance.localUser!);
      } else {
        for (var user in ZEGOSDKManager.instance.expressService.userInfoList) {
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
              child: const Text('Start Live', style: TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  void startLive() {
    isLivingNotifier.value = true;
    ZEGOSDKManager.instance.loginRoom(widget.roomID).then(
      (value) {
        if (value.errorCode != 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
        } else {
          final userID = ZEGOSDKManager.instance.localUser?.userID;
          final hostStreamID = '${widget.roomID}_${userID}_host';
          ZEGOSDKManager.instance.expressService.startPublishingStream(hostStreamID);
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
            style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 104, 94, 94)),
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
        final streamIDPrefix = '${event.roomID}_${user.userID}_';
        cohostStreamNotifier.removeWhere((streamID) => streamID.startsWith(streamIDPrefix));
        if (hostUserInfoNotifier.value?.userID == user.userID) {
          hostUserInfoNotifier.value = null;
        }
      }
    }
  }

  void onRoomCustomSignalingReceived(ZIMServiceReceiveRoomCustomSignalingEvent event) {
    Map<String, dynamic> signalingMap = convert.jsonDecode(event.signaling);
    String senderID = signalingMap['senderID'];
    String receiverID = signalingMap['receiverID'];
    final signalingType = signalingMap['type'];
    if (receiverID != ZEGOSDKManager.instance.localUser!.userID) return;
    if (signalingType == CustomSignalingType.audienceApplyToBecomeCoHost) {
      applyCohostList.add(senderID);
      // show dialog
      if (ZEGOSDKManager.instance.getUser(senderID) != null) {
        showApplyCohostDialog(ZEGOSDKManager.instance.getUser(senderID)!);
      }
    } else if (signalingType == CustomSignalingType.audienceCancelCoHostApply) {
      applyCohostList.removeWhere((element) => element == receiverID);
      dismisApplyCohostDialog();
    } else if (signalingType == CustomSignalingType.hostAcceptAudienceCoHostApply) {
      applying.value = false;
      applyCohostList.removeWhere((element) => element == receiverID);

      becomeCoHost();
    } else if (signalingType == CustomSignalingType.hostRefuseAudienceCoHostApply) {
      applying.value = false;
      applyCohostList.removeWhere((element) => element == receiverID);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('host refuse your apply'),
        ),
      );
    }
  }

  void becomeCoHost() {
    final roomID = ZEGOSDKManager.instance.expressService.room;
    final userID = ZEGOSDKManager.instance.localUser!.userID;
    final cohostStreamID = '${roomID}_${userID}_cohost';
    ZEGOSDKManager.instance.expressService.turnCameraOn(true);
    ZEGOSDKManager.instance.expressService.turnMicrophoneOn(true);
    ZEGOSDKManager.instance.expressService.startPreview();
    ZEGOSDKManager.instance.expressService.startPublishingStream(cohostStreamID);
    ZEGOSDKManager.instance.expressService.localUser!.roleNotifier.value = ZegoLiveRole.coHost;
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
                final signaling = jsonEncode({
                  'type': CustomSignalingType.hostRefuseAudienceCoHostApply,
                  'senderID': ZEGOSDKManager.instance.localUser!.userID,
                  'receiverID': userInfo.userID,
                });
                ZEGOSDKManager.instance.zimService.sendRoomCustomSignaling(signaling).then((value) {
                  Navigator.pop(context);
                }).catchError((error) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('refuse cohost failed: ${error.code},${error.message}')));
                });
              },
            ),
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                final signaling = jsonEncode({
                  'type': CustomSignalingType.hostAcceptAudienceCoHostApply,
                  'senderID': ZEGOSDKManager.instance.localUser!.userID,
                  'receiverID': userInfo.userID,
                });
                ZEGOSDKManager.instance.zimService.sendRoomCustomSignaling(signaling).then((value) {
                  Navigator.pop(context);
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('accept apply cohost failed: ${error.code},${error.message}')));
                });
              },
            ),
          ],
        );
      },
    ).whenComplete(() => showingDialog = false);
  }
}
