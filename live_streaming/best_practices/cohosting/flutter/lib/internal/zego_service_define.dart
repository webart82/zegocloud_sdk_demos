import 'package:zego_express_engine/zego_express_engine.dart';

export 'zego_express_service.dart';
export 'zego_express_service_event.dart';
export 'zego_user_Info.dart';

class ZegoRoomUserListUpdateEvent {
  final String roomID;
  final ZegoUpdateType updateType;
  final List<ZegoUser> userList;

  ZegoRoomUserListUpdateEvent(this.roomID, this.updateType, this.userList,);
}

class ZegoRoomStreamListUpdateEvent {
  final String roomID;
  final ZegoUpdateType updateType;
  final List<ZegoStream> streamList;
  final Map<String, dynamic> extendedData;

  ZegoRoomStreamListUpdateEvent(this.roomID, this.updateType, this.streamList, this.extendedData);
}

class ZegoRoomCustomCommandEvent {
   final String roomID;
   final ZegoUser fromUser;
   final String command;

   ZegoRoomCustomCommandEvent(this.roomID, this.fromUser, this.command);
}

class ZegoRoomStreamExtraInfoEvent {
   final String roomID;
   final List<ZegoStream> streamList;

   ZegoRoomStreamExtraInfoEvent(this.roomID, this.streamList);
}