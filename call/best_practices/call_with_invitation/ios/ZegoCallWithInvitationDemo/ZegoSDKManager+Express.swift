//
//  ZegoSDKManager+Express.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/13.
//

import Foundation
import ZegoExpressEngine

extension ZegoSDKManager {
    
    func addEventHandler(_ eventHandle: ZegoEventHandler) {
        expressEventDelegates.add(eventHandle)
    }
    
    func joinRoom(userID: String, userName: String, roomID: String, callBack: ExpressJoinRoomCallback?) {
        ExpressService.shared.joinRoom(userID: userID, userName: userName, roomID: roomID, callBack: callBack)
    }
    
    func leaveRoom() {
        ExpressService.shared.leaveRoom()
    }
    
    func playingStream(_ streamID: String, canvas: ZegoCanvas?) {
        ExpressService.shared.playingStream(streamID, canvas: canvas)
    }
    
    func stopPlayingStream(_ streamID: String) {
        ExpressService.shared.stopPlayingStream(streamID)
    }
    
    func startPublishingStream() {
        ExpressService.shared.startPublishingStream()
    }
    
    func stopPublishingStream() {
        ExpressService.shared.stopPublishingStream()
    }
    
    func setLocalVideoView(renderView: UIView, videoMode: ZegoViewMode = .aspectFill) {
        ExpressService.shared.setLocalVideoView(renderView: renderView, videoMode: videoMode)
    }
    
    func setRemoteVideoView(userID: String, renderView: UIView, videoMode: ZegoViewMode = .aspectFill) {
        ExpressService.shared.setRemoteVideoView(userID: userID, renderView: renderView, videoMode: videoMode)
    }
    
    //MARK: -Device
    func useFrontFacingCamera(isFrontFacing: Bool) {
        ExpressService.shared.useFrontFacingCamera(isFrontFacing: isFrontFacing)
    }
    
    func enableSpeaker(enable: Bool) {
        ExpressService.shared.enableSpeaker(enable: enable)
    }
    
    func turnMicrophoneOn(_ isOn: Bool) {
        ExpressService.shared.turnMicrophoneOn(isOn)
    }
    
    func turnCameraOn(_ isOn: Bool) {
        ExpressService.shared.turnCameraOn(isOn)
    }
    
    func isMicrophoneOn(_ userID: String) -> Bool {
        return ExpressService.shared.isMicrophoneOn(userID)
    }
    
    func isCameraOn(_ userID: String) -> Bool {
        return ExpressService.shared.isCameraOn(userID)
    }
}
