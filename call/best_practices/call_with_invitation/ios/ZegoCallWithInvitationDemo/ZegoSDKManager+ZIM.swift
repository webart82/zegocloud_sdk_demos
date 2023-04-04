//
//  ZegoSDKManager+ZIM.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import Foundation
import ZIM

extension ZegoSDKManager {
    
    func addZIMEventHandler(_ eventHandle: ZIMEventHandler) {
        zimEventHandlers.add(eventHandle)
    }
    
    func connectUser(userID: String, userName: String, token: String?, callback: ConnectUserCallback?) {
        ExpressService.shared.localParticipant = ZegoParticipant(userID: userID, name: userName)
        ZIMService.shared.connectUser(userID: userID, userName: userName, token: token, callback: callback)
    }
    
    func loginOut() {
        ZIMService.shared.disconnectUser()
    }
    
    //MARK - invitation
    func sendCallInvitation(with invitees: [String], type: CallType, callback: SendCallInvitationCallback?) {
        guard let localUser = localUser else { return }
        let callType: String = type == .voice ? "voice_call" : "video_call"
        let extendedData: [String : AnyObject] = ["type": callType as AnyObject, "userName": localUser.userName as AnyObject]
        ZIMService.shared.sendCallInvitation(with: invitees, data: extendedData.jsonString) { errorCode, errorMessage, invitationID, errorInvitees in
            if errorCode == 0 {
                let invitee: UserInfo = UserInfo(userID: invitees.first ?? "")
                ZegoCallStateManager.shared.createCallData(invitationID, inviter: localUser, invitee: invitee, type: type, callStatus: .wating)
            } else {
                ZegoCallStateManager.shared.clearCallData()
            }
            guard let callback = callback else { return }
            callback(errorCode, errorMessage, invitationID, errorInvitees)
        }
    }
    
    func cancelCallInvitation(with invitees: [String], invitationID: String, data: String?, callback: CancelCallInvitationCallback?) {
        ZegoCallStateManager.shared.clearCallData()
        ZIMService.shared.cancelCallInvitation(with: invitees, invitationID: invitationID, data: data, callback: callback)
    }
    
    func rejectCallInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        if invitationID == ZegoCallStateManager.shared.currentCallData?.callID {
            ZegoCallStateManager.shared.clearCallData()
        }
        ZIMService.shared.rejectCallInvitation(with: invitationID, data: data, callback: callback)
    }
    
    func acceptCallInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        ZegoCallStateManager.shared.updateCallData(callStatus: .accept)
        ZIMService.shared.acceptCallInvitation(with: invitationID, data: data, callback: callback)
    }
    
}
