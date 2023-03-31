//
//  ExpressService+EventHandler.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService: ZegoEventHandler {
    public func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        
        for stream in streamList {
            let user = inRoomUserDict[stream.user.userID]
            if updateType == .add {
                streamDict[stream.user.userID] = stream.streamID
                user?.streamID = stream.streamID
            } else {
                streamDict.removeValue(forKey: stream.user.userID)
                user?.streamID = nil
            }
        }
        
        delegate?.onRoomStreamUpdate?(updateType, streamList: streamList, extendedData: extendedData, roomID: roomID)
    }
    
    public func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        if updateType == .add {
            for user in userList {
                let user = UserInfo(id: user.userID, name: user.userName)
                user.streamID = streamDict[user.id]
                inRoomUserDict[user.id] = user
            }
        } else {
            for user in userList {
                inRoomUserDict.removeValue(forKey: user.userID)
            }
        }
        delegate?.onRoomUserUpdate?(updateType, userList: userList, roomID: roomID)
    }
    
    public func onRoomOnlineUserCountUpdate(_ count: Int32, roomID: String) {
        delegate?.onRoomOnlineUserCountUpdate?(count, roomID: roomID)
    }
    
    public func onIMRecvCustomCommand(_ command: String, from fromUser: ZegoUser, roomID: String) {
        let commandStr = command
        guard let command = CustomCommandBuilder.build(command) else {
            assertionFailure("Receive a error command!")
            return
        }
        
        delegate?.onInRoomCommandReceived(command, from: fromUser.userID)
        
        delegate?.onIMRecvCustomCommand?(commandStr, from: fromUser, roomID: roomID)
    }
}
