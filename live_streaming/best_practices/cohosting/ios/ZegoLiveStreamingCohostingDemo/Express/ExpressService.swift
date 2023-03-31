//
//  ExpressService.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import Foundation
import ZegoExpressEngine

public class ExpressService: NSObject {
    
    public var localUser: UserInfo?
    
    public weak var delegate: ExpressServiceDelegate?
    
    public var isUsingFrontCamera: Bool = true
    
    public var roomID: String?
    
    public var isHost: Bool = false
    
    // UserID: StreamID
    public var streamDict: [String: String] = [:]
    
    // UserID: UserInfo
    public var inRoomUserDict: [String: UserInfo] = [:]
    
    public var host: UserInfo? {
        inRoomUserDict.values.first(where: { $0.role == .host })
    }
    
    public func initWith(appID: UInt32, appSign: String) {
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.appSign = appSign
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)
    }
    
    public func uinit() {
        ZegoExpressEngine.destroy()
    }
    
    public func connectUser(userID: String,
                     userName: String? = nil,
                     callback: ConnectUserCallback? = nil) {
        let userName = userName ?? userID
        localUser = UserInfo(id: userID, name: userName)
        inRoomUserDict[userID] = localUser
        callback?(0)
    }
    
    public func disconnectUser() {
        localUser = nil
    }
}
