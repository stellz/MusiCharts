//
//  Settings.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation

struct Settings {

    let scrobbling: Scrobbling

    struct Scrobbling {
        
        let audioEnabled: Bool
        let radioEnabled: Bool
    }
    
    var debugDescription: String {
        return "radioEnabled:\(scrobbling.radioEnabled), audioEnabled:\(scrobbling.audioEnabled)"
    }
}

struct Credentials {
    
    let sessionName: String
    let sessionKey: String

    let userInfo: UserInfo
    
    struct UserInfo {
        
        let realName: String
        let registeredSince: String
        let imageUrlPath: String
    }

}
