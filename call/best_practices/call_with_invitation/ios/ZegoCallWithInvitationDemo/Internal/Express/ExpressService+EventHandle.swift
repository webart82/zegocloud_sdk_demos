//
//  ExpressService+EventHandle.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import Foundation
import ZegoExpressEngine

extension ExpressService: ZegoEventHandler {
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        for user in userList {
            if updateType == .add {
                let participant: ZegoParticipant = self.participantDic[user.userID] ?? ZegoParticipant.init(userID: user.userID, name: user.userName)
                participant.name = user.userName
                participantDic[user.userID] = participant
            } else {
                let participant: ZegoParticipant? = self.participantDic[user.userID] ?? nil
                if let participant = participant {
                    self.stopPlayingStream(participant.streamID)
                }
                participantDic.removeValue(forKey: user.userID)
            }
        }
        for delegate in expressEventDelegates.allObjects {
            delegate.onRoomUserUpdate?(updateType, userList: userList, roomID: roomID)
        }
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        for stream in streamList {
            if updateType == .add {
                self.streamDic[stream.streamID] = stream.user.userID
                var participant: ZegoParticipant? = self.participantDic[stream.user.userID]
                if let participant = participant {
                    participant.streamID = stream.streamID
                    participant.name = stream.user.userName
                } else {
                    participant = ZegoParticipant.init(userID: stream.user.userID, name: stream.user.userName)
                    participant?.streamID = stream.streamID
                }
                self.participantDic[stream.user.userID] = participant
            } else {
                self.streamDic.removeValue(forKey: stream.streamID)
                let participant = self.participantDic[stream.user.userID]
                participant?.streamID = ""
                if let participant = participant {
                    self.participantDic[stream.user.userID] = participant
                }
            }
        }
        
        
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
        if let userID = streamDic[streamID],
           let participant = participantDic[userID]
        {
            participant.camera = state == .open ? true : false
        }
        for delegate in expressEventDelegates.allObjects {
            delegate.onRemoteCameraStateUpdate?(state, streamID: streamID)
        }
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        if let userID = streamDic[streamID],
           let participant = participantDic[userID]
        {
            participant.mic = state == .open ? true : false
        }
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
