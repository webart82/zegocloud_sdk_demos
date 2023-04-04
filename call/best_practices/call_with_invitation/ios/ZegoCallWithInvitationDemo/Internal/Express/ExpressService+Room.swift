//
//  ExpressService+Room.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import Foundation
import ZegoExpressEngine

typealias ExpressJoinRoomCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

extension ExpressService {
    
    func joinRoom(userID: String, userName: String, roomID: String, callBack: ExpressJoinRoomCallback?) {
        self.roomID = roomID
        let user: ZegoUser = ZegoUser()
        user.userID = userID
        user.userName = userName
        
        let participant: ZegoParticipant = self.localParticipant ?? ZegoParticipant(userID: user.userID, name: user.userName)
        participant.streamID = generateStreamID(userID: participant.userID, roomID: roomID)
        self.participantDic[participant.userID] = participant
        self.streamDic[participant.streamID] = participant.userID
        self.localParticipant = participant
        
        // monitor sound level
        ZegoExpressEngine.shared().startSoundLevelMonitor(1000)
        let config: ZegoRoomConfig = ZegoRoomConfig()
        config.isUserStatusNotify = true
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config) { errorCode, data in
            guard let callBack = callBack else { return }
            if errorCode == 0 {
                callBack(UInt(errorCode), "join room sucess")
            } else {
                callBack(UInt(errorCode), "join room failed")
            }
        }
    }
    
    func leaveRoom() {
        self.roomID = nil
        self.participantDic.removeAll()
        self.streamDic.removeAll()
        ZegoExpressEngine.shared().stopSoundLevelMonitor()
        ZegoExpressEngine.shared().stopPreview()
        ZegoExpressEngine.shared().stopPublishingStream()
        ZegoExpressEngine.shared().logoutRoom { errorCode, dict in
            print("logout room errorCode: %d",errorCode)
        }
    }
    
}


