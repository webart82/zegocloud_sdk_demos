//
//  ExpressService+Command.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/6.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    public func SendInRoomCommand(_ command: CustomCommand,
                                  callback: InRoomCommnadCallback?) {
        
        guard let roomID = roomID else {
            assertionFailure("Please join the room first!")
            callback?(-1)
            return
        }
        
        guard let commandStr = command.jsonString() else {
            assertionFailure("Command error: \(command)")
            callback?(-1)
            return
        }
        
        let user = ZegoUser(userID: command.targetID)
        ZegoExpressEngine.shared().sendCustomCommand(commandStr, toUserList: [user], roomID: roomID) { error in
            callback?(error)
        }
    }
}
