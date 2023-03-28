//
//  ExpressService+Stream.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/14.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    
    func playingStream(_ streamID: String, canvas: ZegoCanvas?) {
        if let canvas = canvas {
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID)
        }
    }
    
    func stopPlayingStream(_ streamID: String) {
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
    }
    
    func startPublishingStream() {
        guard let streamID = self.localParticipant?.streamID else { return }
        ZegoExpressEngine.shared().startPublishingStream(streamID)
    }
    
    func stopPublishingStream() {
        guard let _ = self.localParticipant?.streamID else { return }
        ZegoExpressEngine.shared().stopPublishingStream()
        ZegoExpressEngine.shared().stopPreview()
    }
    
    func setLocalVideoView(renderView: UIView, videoMode: ZegoViewMode) {
        guard let userID = localParticipant?.userID else {
            print("Error: [setVideoView] please login room pre")
            return
        }
        let participant = participantDic[userID] ?? ZegoParticipant(userID: userID, name: "")
        if let roomID = roomID {
            participant.streamID = generateStreamID(userID: userID, roomID: roomID)
            self.streamDic[participant.streamID] = participant.userID
        }
        participant.renderView = renderView
        participant.videoDisPlayMode = videoMode
        self.participantDic[userID] = participant
        ZegoExpressEngine.shared().startPreview(generateCanvas(rendView: renderView, videoMode: videoMode))
    }
    
    func setRemoteVideoView(userID: String, renderView: UIView, videoMode: ZegoViewMode) {
        guard let roomID = roomID else {
            print("Error: [setVideoView] You need to join the room first and then set the videoView")
            return
        }
        guard let _ = localParticipant?.userID else {
            print("Error: [setVideoView] userID is empty, please enter a right userID")
            return
        }
        let participant = self.participantDic[userID] ?? ZegoParticipant(userID: userID,name: "")
        participant.streamID = generateStreamID(userID: userID, roomID: roomID)
        participant.renderView = renderView
        participant.videoDisPlayMode = videoMode
        self.participantDic[userID] = participant
        self.streamDic[participant.streamID] = participant.userID
        let canvas = generateCanvas(rendView: renderView, videoMode: videoMode)
        playingStream(participant.streamID, canvas: canvas)
    }
    
    private func generateCanvas(rendView: UIView?, videoMode: ZegoViewMode) -> ZegoCanvas? {
        guard let rendView = rendView else {
            return nil
        }
        let canvas = ZegoCanvas(view: rendView)
        canvas.viewMode = videoMode
        return canvas
    }

}
