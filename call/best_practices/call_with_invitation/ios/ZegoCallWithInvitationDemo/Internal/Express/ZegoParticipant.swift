//
//  ZegoParticipant.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit
import ZegoExpressEngine

class ZegoParticipant: NSObject {
    let userID: String
    var name: String = ""
    var streamID: String = ""
    var renderView: UIView = UIView()
    var camera: Bool = false
    var mic: Bool = false
    var videoDisPlayMode: ZegoViewMode = .aspectFill
    
    init(userID: String, name: String) {
        self.userID = userID
        self.name = name
    }
    
    func toUserInfo() -> UserInfo {
        let user: UserInfo = UserInfo(userID: userID, userName: name)
        return user
    }
}
