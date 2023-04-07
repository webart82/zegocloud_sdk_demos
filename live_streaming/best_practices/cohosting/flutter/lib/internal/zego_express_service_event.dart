export 'zego_service_define.dart';
import 'package:live_streaming_with_cohosting/internal/zego_express_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

mixin ZegoExpressServiceEvent {
  void uninitEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onIMRecvCustomCommand = null;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = null;
    // ZegoExpressEngine.onRemoteCameraStateUpdate = null;
    // ZegoExpressEngine.onRemoteMicStateUpdate = null;
    // ZegoExpressEngine.onRoomStateChanged = null;
  }

  void initEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate =
        ZegoExpressService.shared.onRoomStreamUpdate;

    ZegoExpressEngine.onRoomUserUpdate =
        ZegoExpressService.shared.onRoomUserUpdate;

    ZegoExpressEngine.onIMRecvCustomCommand =
        ZegoExpressService.shared.onIMRecvCustomCommand;

    ZegoExpressEngine.onRoomStreamExtraInfoUpdate =
        ZegoExpressService.shared.onRoomStreamExtraInfoUpdate;

    // ZegoExpressEngine.onRemoteCameraStateUpdate =
    //     ZegoExpressService.shared.core.onRemoteCameraStateUpdate;

    // ZegoExpressEngine.onRemoteMicStateUpdate =
    //     ZegoExpressService.shared.core.onRemoteMicStateUpdate;

    // ZegoExpressEngine.onRoomStateChanged =
    //     ZegoExpressService.shared.core.onRoomStateChanged;
  }
}
