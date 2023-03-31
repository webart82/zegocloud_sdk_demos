//
//  ExpressServiceDelegate.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/3.
//

import Foundation
import ZegoExpressEngine

public protocol ExpressServiceDelegate: ZegoEventHandler {
    func onInRoomCommandReceived(_ command: CustomCommand, from userID: String)
}
