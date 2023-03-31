//
//  ExpressService+Device.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

extension ExpressService {
    public func useFrontFacingCamera(_ isFrontFacing: Bool) {
        isUsingFrontCamera = isFrontFacing
        ZegoExpressEngine.shared().useFrontCamera(isFrontFacing)
    }
    
    public func turnMicrophoneOn(_ isOn: Bool) {
        ZegoExpressEngine.shared().muteMicrophone(!isOn)
    }
    
    public func turnCameraOn(_ isOn: Bool) {
        ZegoExpressEngine.shared().enableCamera(isOn)
    }
}
