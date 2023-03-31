//
//  CustomCommand.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/4/6.
//

import Foundation

public struct CustomCommand: Codable {
    public var actionType: CustomCommandActionType
    public var operatorID: String
    public var targetID: String
        
    public func jsonString() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            if let str = String(data: data, encoding: .utf8) {
                return str
            }
        } catch {
            return nil
        }
        return nil
    }
}

public struct CustomCommandBuilder {
    public static func build(_ jsonString: String) -> CustomCommand? {
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let command = try JSONDecoder().decode(CustomCommand.self, from: jsonData)
                return command
            } catch {
                return nil
            }
        }
        return nil
    }
}
