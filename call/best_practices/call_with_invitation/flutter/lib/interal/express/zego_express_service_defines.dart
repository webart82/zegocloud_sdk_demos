import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoCameraStateChangeEvent {
  final ZegoRemoteDeviceState state;

  ZegoCameraStateChangeEvent(this.state);
}

class ZegoMicrophoneStateChangeEvent {
  final ZegoRemoteDeviceState state;

  ZegoMicrophoneStateChangeEvent(this.state);
}

class ZegoRoomUserListUpdateEvent {
  final String roomID;
  final ZegoUpdateType updateType;
  final List<ZegoUser> userList;

  ZegoRoomUserListUpdateEvent(
    this.roomID,
    this.updateType,
    this.userList,
  );
}

class ZegoRoomStreamListUpdateEvent {
  final String roomID;
  final ZegoUpdateType updateType;
  final List<ZegoStream> streamList;
  final Map<String, dynamic> extendedData;

  ZegoRoomStreamListUpdateEvent(this.roomID, this.updateType, this.streamList, this.extendedData);
}
