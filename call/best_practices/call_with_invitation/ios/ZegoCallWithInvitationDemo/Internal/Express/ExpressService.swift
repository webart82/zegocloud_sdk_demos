//
//  ExpressService.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit
import ZegoExpressEngine

class ExpressService: NSObject {
    
    static let shared = ExpressService()
    
    var roomID: String?
    var participantDic: Dictionary<String, ZegoParticipant> = Dictionary()
    var streamDic: Dictionary<String, String> = Dictionary()
    var localParticipant: ZegoParticipant?
    let expressEventDelegates: NSHashTable<ZegoEventHandler> = NSHashTable(options: .weakMemory)
    
    override init() {
        super.init()
    }
    
    func initWithAppID(_ appID: UInt32, appSign: String) {
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.appSign = appSign
        profile.scenario = .default
        let config: ZegoEngineConfig = ZegoEngineConfig()
        config.advancedConfig = ["notify_remote_device_unknown_status": "true", "notify_remote_device_init_status":"true"]
        ZegoExpressEngine.setEngineConfig(config)
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)
    }
    
    func uinit() {
        ZegoExpressEngine.destroy(nil)
    }
    
    func addEventHandler(_ eventHandle: ZegoEventHandler) {
        expressEventDelegates.add(eventHandle)
    }
    
    func generateStreamID(userID: String, roomID: String) -> String {
        if (userID.count == 0) {
            print("Error: [generateStreamID] userID is empty, please enter a right userID")
        }
        if (roomID.count == 0) {
            print("Error: [generateStreamID] roomID is empty, please enter a right roomID")
        }
        
        // The streamID can use any character.
        // For the convenience of query, roomID + UserID + suffix is used here.
        let streamID = String(format: "%@_%@", roomID,userID)
        return streamID
    }
    
}
