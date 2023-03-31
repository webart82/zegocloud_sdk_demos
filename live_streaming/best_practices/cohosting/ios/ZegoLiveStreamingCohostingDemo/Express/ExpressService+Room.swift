//
//  ExpressService+Room.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    public func joinRoom(_ roomID: String, isHost: Bool, callback: JoinRoomCallback? = nil) {
        
        assert(localUser != nil, "Must login first.")
        
        localUser?.role = isHost ? .host : .audience
        
        self.roomID = roomID
        self.isHost = isHost
        
        let userID = localUser?.id ?? ""
        let userName = localUser?.name ?? ""
        let user = ZegoUser(userID: userID, userName: userName)
        
        let config = ZegoRoomConfig()
        config.isUserStatusNotify = true
        
        ZegoExpressEngine.shared().startSoundLevelMonitor(1000)
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config) { error, data in
            callback?(error)
        }
    }
    
    public func leaveRoom() {
        roomID = nil
        ZegoExpressEngine.shared().stopSoundLevelMonitor()
        stopPublishLocalVideo()
        ZegoExpressEngine.shared().logoutRoom()
    }
}
