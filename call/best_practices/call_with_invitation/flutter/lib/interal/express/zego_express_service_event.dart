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
    ZegoExpressEngine.onRoomStreamUpdate =
        ZegoExpressService.shared.core.onRoomStreamUpdate;

    ZegoExpressEngine.onRoomUserUpdate =
        ZegoExpressService.shared.core.onRoomUserUpdate;

    ZegoExpressEngine.onRemoteCameraStateUpdate =
        ZegoExpressService.shared.core.onRemoteCameraStateUpdate;

    ZegoExpressEngine.onRemoteMicStateUpdate =
        ZegoExpressService.shared.core.onRemoteMicStateUpdate;

    ZegoExpressEngine.onRoomStateChanged =
        ZegoExpressService.shared.core.onRoomStateChanged;

  }
}