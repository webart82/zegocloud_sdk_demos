//
//  ZegoSDKManager+ExpressEventHandler.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import Foundation
import ZegoExpressEngine

extension ZegoSDKManager: ZegoEventHandler {
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onRoomUserUpdate?(updateType, userList: userList, roomID: roomID)
        }
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onRoomStreamUpdate?(updateType, streamList: streamList, extendedData: extendedData, roomID: roomID)
        }
    }
    
    func onRoomStateChanged(_ reason: ZegoRoomStateChangedReason, errorCode: Int32, extendedData: [AnyHashable : Any], roomID: String) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onRoomStateChanged?(reason, errorCode: errorCode, extendedData: extendedData, roomID: roomID)
        }
    }
    
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onRemoteCameraStateUpdate?(state, streamID: streamID)
        }
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onRemoteMicStateUpdate?(state, streamID: streamID)
        }
    }
    
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onAudioRouteChange?(audioRoute)
        }
    }
        
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onRemoteSoundLevelUpdate?(soundLevels)
        }
    }
    
    func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        for delegate in expressEventDelegates.allObjects {
            delegate.onCapturedSoundLevelUpdate?(soundLevel)
        }
    }
    
}
