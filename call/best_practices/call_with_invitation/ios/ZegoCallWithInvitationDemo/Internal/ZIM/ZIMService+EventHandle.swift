//
//  ZIMService+EventHandle.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import Foundation
import ZIM

extension ZIMService: ZIMEventHandler {
    
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, connectionStateChanged: state, event: event, extendedData: extendedData)
        }
    }
    
    // MARK: - Main
    func zim(_ zim: ZIM, errorInfo: ZIMError) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, errorInfo: errorInfo)
        }
    }
    
    func zim(_ zim: ZIM, tokenWillExpire second: UInt32) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, tokenWillExpire: second)
        }
    }
    
    func zim(_ zim: ZIM, roomMemberJoined memberList: [ZIMUserInfo], roomID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, roomMemberJoined: memberList, roomID: roomID)
        }
    }
    
    func zim(_ zim: ZIM, roomMemberLeft memberList: [ZIMUserInfo], roomID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, roomMemberLeft: memberList, roomID: roomID)
        }
    }
    
    // MARK: - Invitation
    func zim(_ zim: ZIM, callInvitationReceived info: ZIMCallInvitationReceivedInfo, callID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, callInvitationReceived: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationCancelled info: ZIMCallInvitationCancelledInfo, callID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, callInvitationCancelled: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationAccepted info: ZIMCallInvitationAcceptedInfo, callID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, callInvitationAccepted: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationRejected info: ZIMCallInvitationRejectedInfo, callID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, callInvitationRejected: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationTimeout callID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, callInvitationTimeout: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInviteesAnsweredTimeout invitees: [String], callID: String) {
        for handler in zimEventHandlers.allObjects {
            handler.zim?(zim, callInviteesAnsweredTimeout: invitees, callID: callID)
        }
    }
    
}
