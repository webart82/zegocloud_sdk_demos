//
//  ZIMService+Call.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import Foundation
import ZIM

typealias InvitationCallback = (_ errorCode: UInt, _ errorMessage: String, _ invitationID: String, _ errorInvitees: [String]) -> ()
typealias CancelInvitationCallback = (_ errorCode: UInt, _ errorMessage: String, _ errorInvitees: [String]) -> ()

public typealias ResponseInvitationCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

extension ZIMService {
    
    func sendInvitation(with invitees: [String], data: String?, callback: InvitationCallback?) {
        let config = ZIMCallInviteConfig()
        config.timeout = 60
        config.extendedData = data ?? ""
        zim?.callInvite(with: invitees, config: config, callback: { callID, info, error in
            let code = error.code.rawValue
            let message = error.message
            let errorInvitees = info.errorInvitees.compactMap({ $0.userID })
            callback?(code, message, callID, errorInvitees)
        })
    }
    
    func cancelInvitation(with invitees: [String], invitationID: String, data: String?, callback: CancelInvitationCallback?) {
        let config = ZIMCallCancelConfig()
        config.extendedData = data ?? ""
        zim?.callCancel(with: invitees, callID: invitationID, config: config, callback: { callID, errorInvitees, error in
            let code = error.code.rawValue
            let message = error.message
            callback?(code, message, errorInvitees)
        })
    }
    
    func refuseInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        let config = ZIMCallRejectConfig()
        config.extendedData = data ?? ""
        zim?.callReject(with: invitationID, config: config, callback: { callID, error in
            callback?(error.code.rawValue, error.message)
        })
    }
    
    func acceptInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        let config = ZIMCallAcceptConfig()
        config.extendedData = data ?? ""
        zim?.callAccept(with: invitationID, config: config, callback: { callID, error in
            callback?(error.code.rawValue, error.message)
        })
    }
    
}
