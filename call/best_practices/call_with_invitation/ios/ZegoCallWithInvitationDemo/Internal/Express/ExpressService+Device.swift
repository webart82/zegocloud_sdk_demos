//
//  Express+Device.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/9.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    
    func useFrontFacingCamera(isFrontFacing: Bool) {
        ZegoExpressEngine.shared().useFrontCamera(isFrontFacing)
    }
    
    func enableSpeaker(enable: Bool) {
        ZegoExpressEngine.shared().setAudioRouteToSpeaker(enable)
    }
    
    func isMicrophoneOn(_ userID: String) -> Bool {
        guard let participant = participantDic[userID] else { return false }
        return participant.mic
    }
    
    func isCameraOn(_ userID: String) -> Bool {
        guard let participant = participantDic[userID] else { return false }
        return participant.camera
    }
    
    func turnMicrophoneOn(_ isOn: Bool) {
        guard let localParticipant = localParticipant else { return }
        localParticipant.mic = isOn
        participantDic[localParticipant.userID] = localParticipant
        ZegoExpressEngine.shared().muteMicrophone(!isOn)
    }
    
    func turnCameraOn(_ isOn: Bool) {
        guard let localParticipant = localParticipant else { return }
        localParticipant.camera = isOn
        participantDic[localParticipant.userID] = localParticipant
        ZegoExpressEngine.shared().enableCamera(isOn)
    }
    
}
