//
//  ZegoSDKManager+ZIMEventHandler.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import Foundation
import ZIM

extension ZegoSDKManager: ZIMEventHandler {
    
    func zim(_ zim: ZIM, callInvitationReceived info: ZIMCallInvitationReceivedInfo, callID: String) {
        if let currentCallData = ZegoCallStateManager.shared.currentCallData {
            if currentCallData.callStatus == .wating || currentCallData.callStatus == .accept {
                let dataDict: [String : AnyObject] = ["reason":"busy" as AnyObject, "callID": callID as AnyObject]
                rejectCallInvitation(with: callID, data: dataDict.jsonString, callback: nil)
                return
            }
        }
        let extentedData: [String : AnyObject]? =  info.extendedData.convertStringToDictionary()
        let userName: String = (extentedData?["userName"] as? String) ?? ""
        let inviter: UserInfo = UserInfo(userID: info.inviter,userName: userName)
        let type: String = (extentedData?["type"] as? String) ?? "voice_call"
        var callType: CallType = .voice
        if type == "voice_call" {
            callType = .voice
        } else {
            callType = .video
        }
        if let localUser = localUser {
            ZegoCallStateManager.shared.createCallData(callID, inviter: inviter, invitee: localUser, type: callType, callStatus: .wating)
        }
        for delegate in zimEventHandlers.allObjects {
            delegate.zim?(zim, callInvitationReceived: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationAccepted info: ZIMCallInvitationAcceptedInfo, callID: String) {
        ZegoCallStateManager.shared.updateCallData(callStatus: .accept)
        for delegate in zimEventHandlers.allObjects {
            delegate.zim?(zim, callInvitationAccepted: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationRejected info: ZIMCallInvitationRejectedInfo, callID: String) {
        ZegoCallStateManager.shared.updateCallData(callStatus: .reject)
        ZegoCallStateManager.shared.clearCallData()
        for delegate in zimEventHandlers.allObjects {
            delegate.zim?(zim, callInvitationRejected: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationCancelled info: ZIMCallInvitationCancelledInfo, callID: String) {
        ZegoCallStateManager.shared.updateCallData(callStatus: .cancel)
        ZegoCallStateManager.shared.clearCallData()
        for delegate in zimEventHandlers.allObjects {
            delegate.zim?(zim, callInvitationCancelled: info, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInvitationTimeout callID: String) {
        ZegoCallStateManager.shared.updateCallData(callStatus: .timeout)
        ZegoCallStateManager.shared.clearCallData()
        for delegate in zimEventHandlers.allObjects {
            delegate.zim?(zim, callInvitationTimeout: callID)
        }
    }
    
    func zim(_ zim: ZIM, callInviteesAnsweredTimeout invitees: [String], callID: String) {
        ZegoCallStateManager.shared.updateCallData(callStatus: .timeout)
        ZegoCallStateManager.shared.clearCallData()
        for delegate in zimEventHandlers.allObjects {
            delegate.zim?(zim, callInviteesAnsweredTimeout: invitees, callID: callID)
        }
    }
    
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        for delegate in zimEventHandlers.allObjects {
            delegate.zim?(zim, connectionStateChanged: state, event: event, extendedData: extendedData)
        }
    }
}
