//
//  ZIMService.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit
import ZIM

typealias ConnectUserCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()
typealias RenewTokenCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

class ZIMService: NSObject {
    
    static let shared = ZIMService()
    var zim: ZIM? = nil
    var userInfo: ZIMUserInfo? = nil
    
    let zimEventHandlers: NSHashTable<ZIMEventHandler> = NSHashTable(options: .weakMemory)
    
    override init() {
        super.init()
    }
    
    func initWithAppID(_ appID: UInt32, appSign: String?) {
        let zimConfig: ZIMAppConfig = ZIMAppConfig()
        zimConfig.appID = appID
        zimConfig.appSign = appSign ?? ""
        self.zim = ZIM.shared()
        if self.zim == nil {
            self.zim = ZIM.create(with: zimConfig)
        }
        self.zim?.setEventHandler(self)
    }
    
    func connectUser(userID: String, userName: String, token: String?, callback: ConnectUserCallback?) {
        let user = ZIMUserInfo()
        user.userID = userID
        user.userName = userName
        userInfo = user
        zim?.login(with: user, token: token ?? "") { error in
            callback?(error.code.rawValue, error.message)
        }
    }
    
    func disconnectUser() {
        zim?.logout()
    }
    
    func renewToken(_ token: String, callback: RenewTokenCallback?) {
        zim?.renewToken(token) { token, error in
            callback?(error.code.rawValue, error.message)
        }
    }
    
    func addZIMEventHandler(_ handler: ZIMEventHandler) {
        zimEventHandlers.add(handler)
    }

}
