//
//  ZegoSDKManager.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit
import ZegoExpressEngine
import ZIM

class ZegoSDKManager: NSObject {
    
    static let shared = ZegoSDKManager()
    var localUser: UserInfo? {
        get {
            return ExpressService.shared.localParticipant?.toUserInfo()
        }
    }
    
    let expressEventDelegates: NSHashTable<ZegoEventHandler> = NSHashTable(options: .weakMemory)
    let zimEventHandlers: NSHashTable<ZIMEventHandler> = NSHashTable(options: .weakMemory)
    
    override init() {
        super.init()
        ExpressService.shared.addEventHandler(self)
        ZIMService.shared.addZIMEventHandler(self)
    }
    
    func initWithAppID(_ appID: UInt32, appSign: String) {
        ExpressService.shared.initWithAppID(appID, appSign: appSign)
        ZIMService.shared.initWithAppID(appID, appSign: appSign)
    }
    
    func uinit() {
        ExpressService.shared.uinit()
    }

}


