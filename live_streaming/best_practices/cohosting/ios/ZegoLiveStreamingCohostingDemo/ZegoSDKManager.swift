//
//  ZegoSDKManager.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import UIKit
import ZegoExpressEngine

class ZegoSDKManager {
    
    static let shared = ZegoSDKManager()
    
    var expressService = ExpressService()
    
    var localUser: UserInfo? {
        expressService.localUser
    }
    
    public func initWith(appID: UInt32, appSign: String) {
        expressService.initWith(appID: appID, appSign: appSign)
    }
    
    public func uninit() {
        expressService.uinit()
    }
    
    public func connectUser(userID: String,
                            userName: String? = nil,
                            callback: ConnectUserCallback? = nil) {
        expressService.connectUser(userID: userID,
                                   userName: userName,
                                   callback: callback)
    }
    
    public func disconnectUser() {
        expressService.disconnectUser()
    }
}
