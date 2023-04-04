//
//  ZIMService+Call.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import Foundation
import ZIM

typealias SendCallInvitationCallback = (_ errorCode: UInt, _ errorMessage: String, _ invitationID: String, _ errorInvitees: [String]) -> ()
typealias CancelCallInvitationCallback = (_ errorCode: UInt, _ errorMessage: String, _ errorInvitees: [String]) -> ()

public typealias ResponseInvitationCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

extension ZIMService {
    
    func sendCallInvitation(with invitees: [String], data: String?, callback: SendCallInvitationCallback?) {
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
    
    func cancelCallInvitation(with invitees: [String], invitationID: String, data: String?, callback: CancelCallInvitationCallback?) {
        let config = ZIMCallCancelConfig()
        config.extendedData = data ?? ""
        zim?.callCancel(with: invitees, callID: invitationID, config: config, callback: { callID, errorInvitees, error in
            let code = error.code.rawValue
            let message = error.message
            callback?(code, message, errorInvitees)
        })
    }
    
    func rejectCallInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        let config = ZIMCallRejectConfig()
        config.extendedData = data ?? ""
        zim?.callReject(with: invitationID, config: config, callback: { callID, error in
            callback?(error.code.rawValue, error.message)
        })
    }
    
    func acceptCallInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        let config = ZIMCallAcceptConfig()
        config.extendedData = data ?? ""
        zim?.callAccept(with: invitationID, config: config, callback: { callID, error in
            callback?(error.code.rawValue, error.message)
        })
    }
    
}
