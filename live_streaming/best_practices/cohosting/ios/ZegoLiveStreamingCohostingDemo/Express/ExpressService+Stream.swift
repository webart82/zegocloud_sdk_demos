//
//  ExpressService+Stream.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    
    public func startCameraPreview(_ renderView: UIView,
                            viewMode: ZegoViewMode = .aspectFill) {
        let canvas = ZegoCanvas(view: renderView)
        canvas.viewMode = viewMode
        ZegoExpressEngine.shared().startPreview(canvas)
    }
    
    public func stopCameraPreview() {
        ZegoExpressEngine.shared().stopPreview()
    }
    
    public func startPublishLocalVideo() {
        ZegoExpressEngine.shared().startPublishingStream(generateStreamID())
    }

    public func stopPublishLocalVideo() {
        ZegoExpressEngine.shared().stopPublishingStream()
        ZegoExpressEngine.shared().stopPreview()
    }
    
    public func startPlayRemoteAudioVideo(_ renderView: UIView?,
                                   streamID: String,
                                   viewMode: ZegoViewMode = .aspectFill) {
        if let renderView = renderView {
            let canvas = ZegoCanvas(view: renderView)
            canvas.viewMode = viewMode
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID)
        }
    }
    
    public func stopPlayRemoteAudioVideo(_ streamID: String) {
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
    }
    
    private func generateStreamID() -> String {
        assert(localUser != nil, "Must login first!")
        assert(roomID != nil, "Must join room first!")
        let userID = localUser?.id ?? ""
        let roomID = roomID ?? ""
        let streamID = roomID + "_" + userID + (isHost ? "_host" : "_coHost")
        return streamID
    }
}
