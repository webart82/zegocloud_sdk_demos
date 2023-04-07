import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../define.dart';

/// switch cameras
class ZegoToggleMicrophoneButton extends StatefulWidget {
  const ZegoToggleMicrophoneButton({
    Key? key,
    this.onPressed,
    this.icon,
    this.iconSize,
    this.buttonSize,
  }) : super(key: key);

  final ButtonIcon? icon;

  ///  You can do what you want after pressed.
  final void Function()? onPressed;

  /// the size of button's icon
  final Size? iconSize;

  /// the size of button
  final Size? buttonSize;

  @override
  State<ZegoToggleMicrophoneButton> createState() =>
      _ZegoToggleMicrophoneButtonState();
}

class _ZegoToggleMicrophoneButtonState
    extends State<ZegoToggleMicrophoneButton> {
  ValueNotifier<bool> micStateNoti = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = widget.buttonSize ?? Size(96, 96);
    final sizeBoxSize = widget.iconSize ?? Size(56, 56);

    return ValueListenableBuilder<bool>(
        valueListenable: micStateNoti,
        builder: (context, micState, _) {
          return GestureDetector(
            onTap: () {
              if (widget.onPressed != null) {
                micStateNoti.value = !micStateNoti.value;
                widget.onPressed!();
              }
            },
            child: Container(
              width: containerSize.width,
              height: containerSize.height,
              decoration: BoxDecoration(
                color: micState ? Colors.white : Color.fromARGB(255, 51, 52, 56).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: SizedBox.fromSize(
                size: sizeBoxSize,
                child: micState
                    ? Image(
                        image: AssetImage('assets/icons/toolbar_mic_off.png'))
                    : Image(
                        image:
                            AssetImage('assets/icons/toolbar_mic_normal.png')),
              ),
            ),
          );
        });
  }
}