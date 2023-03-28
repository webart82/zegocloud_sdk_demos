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
    func sendInvitation(with invitees: [String], type: CallType, callback: InvitationCallback?) {
        guard let localUser = localUser else { return }
        let callType: String = type == .voice ? "voice_call" : "video_call"
        let extendedData: [String : AnyObject] = ["type": callType as AnyObject, "userName": localUser.userName as AnyObject]
        ZIMService.shared.sendInvitation(with: invitees, data: extendedData.jsonString) { errorCode, errorMessage, invitationID, errorInvitees in
            if errorCode == 0 {
                let invitee: UserInfo = UserInfo(userID: invitees.first ?? "")
                ZegoCallDataManager.shared.createCallData(invitationID, inviter: localUser, invitee: invitee, type: type, callStatus: .wating)
            } else {
                ZegoCallDataManager.shared.resertCall()
            }
            guard let callback = callback else { return }
            callback(errorCode, errorMessage, invitationID, errorInvitees)
        }
    }
    
    func cancelInvitation(with invitees: [String], invitationID: String, data: String?, callback: CancelInvitationCallback?) {
        ZegoCallDataManager.shared.resertCall()
        ZIMService.shared.cancelInvitation(with: invitees, invitationID: invitationID, data: data, callback: callback)
    }
    
    func refuseInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        if invitationID == ZegoCallDataManager.shared.currentCallData?.callID {
            ZegoCallDataManager.shared.resertCall()
        }
        ZIMService.shared.refuseInvitation(with: invitationID, data: data, callback: callback)
    }
    
    func acceptInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?) {
        ZegoCallDataManager.shared.updateCallData(callStatus: .accept)
        ZIMService.shared.acceptInvitation(with: invitationID, data: data, callback: callback)
    }
    
}
