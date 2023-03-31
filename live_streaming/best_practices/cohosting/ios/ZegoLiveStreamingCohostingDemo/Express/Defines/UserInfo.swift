//
//  UserInfo.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/31.
//

import Foundation

public class UserInfo {
    public var id: String
    
    public var name: String
    
    public var role: UserRole = .audience
    
    public var streamID: String? {
        didSet {
            if let streamID = streamID {
                role = streamID.hasSuffix("_host") ? .host : .coHost
            } else {
                role = .audience
            }
        }
    }
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
