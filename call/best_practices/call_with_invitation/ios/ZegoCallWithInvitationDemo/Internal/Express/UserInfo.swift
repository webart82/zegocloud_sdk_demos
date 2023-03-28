//
//  User.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import UIKit

class UserInfo: NSObject {
    
    var userID: String?
    var userName: String?
    
    init(userID: String, userName: String = "") {
        self.userID = userID
        self.userName = userName
    }
}
