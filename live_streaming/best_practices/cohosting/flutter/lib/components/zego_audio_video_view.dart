import 'package:flutter/material.dart';
import 'package:live_streaming_with_cohosting/internal/zego_express_service.dart';

class ZegoAudioVideoView extends StatefulWidget {
  const ZegoAudioVideoView({required this.userInfo, super.key});

  final ZegoUserInfo userInfo;

  @override
  State<ZegoAudioVideoView> createState() => _ZegoAudioVideoViewState();
}

class _ZegoAudioVideoViewState extends State<ZegoAudioVideoView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.userInfo.isCamerOnNoti,
        builder: (context, isCameraOn, _) {
          return createView(isCameraOn);
        });
  }

  Widget createView(bool isCameraOn) {
    if (isCameraOn) {
      return videoView();
    } else {
      if (widget.userInfo.streamID != null) {
        if (widget.userInfo.streamID!.endsWith('_host')) {
          return backGroundView();
        } else {
          return coHostNomalView();
        }
      } else {
        return Container();
      }
    }
  }

  Widget backGroundView() {
    return Image.asset('assets/icons/bg.png');
  }

  Widget coHostNomalView() {
    return Stack(
      children: [
        Container(
          color: Colors.black,
        ),
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              // border: Border.all(width: 1, color: Colors.white),
            ),
            child: Center(
              child: Text(
                widget.userInfo.userName,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget videoView() {
    return ValueListenableBuilder<Widget?>(
        valueListenable: widget.userInfo.canvasNoti,
        builder: (context, view, _) {
          if (view != null) {
            return view;
          } else {
            return Container();
          }
        });
  }
}
