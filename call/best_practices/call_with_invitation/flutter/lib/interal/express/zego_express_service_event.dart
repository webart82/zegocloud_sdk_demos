import 'package:call_with_invitation/interal/express/zego_express_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

mixin ZegoExpressServiceEvent {
  void uninitEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRemoteCameraStateUpdate = null;
    ZegoExpressEngine.onRemoteMicStateUpdate = null;
    ZegoExpressEngine.onRoomStateChanged = null;
  }

  void initEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = ZegoExpressService.instance.core.onRoomStreamUpdate;

    ZegoExpressEngine.onRoomUserUpdate = ZegoExpressService.instance.core.onRoomUserUpdate;

    ZegoExpressEngine.onRemoteCameraStateUpdate = ZegoExpressService.instance.core.onRemoteCameraStateUpdate;

    ZegoExpressEngine.onRemoteMicStateUpdate = ZegoExpressService.instance.core.onRemoteMicStateUpdate;

    ZegoExpressEngine.onRoomStateChanged = ZegoExpressService.instance.core.onRoomStateChanged;
  }
}
