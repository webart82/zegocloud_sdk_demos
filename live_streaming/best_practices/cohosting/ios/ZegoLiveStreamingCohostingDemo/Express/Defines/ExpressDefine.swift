//
//  ExpressDefine.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/6.
//

import Foundation

public typealias ConnectUserCallback = (_ code: UInt) -> Void
public typealias JoinRoomCallback = (_ error: Int32) -> ()
public typealias InRoomCommnadCallback = (_ errorCode: Int32) -> Void


public enum CustomCommandActionType: UInt, Codable {
    // Audience Apply To Become CoHost
    case applyCoHost = 10000
    
    // Audience Cancel CoHost Apply
    case cancelCoHostApply = 10001
    
    // Host Refuse Audience CoHost Apply
    case refuseCoHostApply = 10002
    
    // Host Accept Audience CoHost Apply
    case acceptCoHostApply = 10003
    
    // Host Invite Audience To Become CoHost
    case inviteCoHost = 10100
    
    // Host Cancel CoHost Invitation
    case cancelCoHostInvitation = 10101
    
    // Audience Refuse CoHost Invitation
    case refuseCoHostInvitation = 10102
    
    // Audience Accept CoHost Invitation
    case acceptCoHostInvitation = 10103
}

public enum UserRole: UInt {
    case audience = 1
    case coHost = 2
    case host = 3
}
