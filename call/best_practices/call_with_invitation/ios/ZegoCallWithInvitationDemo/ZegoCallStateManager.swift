//
//  ZegoCallDataManager.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import UIKit

class ZegoCallStateManager: NSObject {
    
    static let shared = ZegoCallStateManager()
    
    var currentCallData: ZegoCallDataModel?
    
    override init() {
        super.init()
    }
    
    func createCallData(_ callID: String, inviter: UserInfo, invitee: UserInfo, type: CallType, callStatus: CallState) {
        currentCallData = ZegoCallDataModel(callID: callID, inviter: inviter, invitee: invitee, type: type, callStatus: callStatus)
    }
    
    func updateCallData(callStatus: CallState) {
        currentCallData?.callStatus = callStatus
    }
    
    func clearCallData() {
        currentCallData = nil
    }

}
