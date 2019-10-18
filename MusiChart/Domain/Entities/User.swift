//
//  User.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation

struct User {
    
    let name: String
    let email: String
    let password: String
    let plays: Int
    let imageURL: String
    let registeredSince: String

    var debugDescription: String {
        return "Name:\(name), Email:\(email), Plays:\(plays), imageURL:\(imageURL)"
    }
    
    init(name: String, email: String, password: String, plays: Int, imageURL: String, registeredSince: String) {
        
        self.name = name
        self.email = email
        self.password = password
        self.plays = plays
        self.imageURL = imageURL
        self.registeredSince = registeredSince
    }
    
    // MARK: - JSON Parsing
    init(from json: [String: Any]) {
        
        self.name = json["realname"] as? String ?? ""
        self.email = json["email"] as? String ?? ""
        self.password = json["password"] as? String ?? ""
        self.plays = Int(json["playcount"] as? String ?? "") ?? 0
        
        let images = json["image"] as? [Any]
        let imageDict = images?.last as? [String: Any]
        let imageURLPath = imageDict?["#text"] as? String
        
        self.imageURL = imageURLPath ?? ""
        
        let registeredInfo = json["registered"] as? [String: Any]
        let registeredTimestamp = TimeInterval(registeredInfo?["unixtime"] as? String ?? "") ?? 0.0
        let registeredTime = Date(timeIntervalSince1970: registeredTimestamp)
        let description = registeredTime.description(with: Locale(identifier: "en_US"))
        let mainPart = description.components(separatedBy: "at")[0]
        let components = mainPart.components(separatedBy: ",")
        var dateString = ""
        if components.count >= 3 {
            dateString = components[1] + "," + components[2]
            if kDebugLog { print("Registered since:", dateString) }
        }
        
        self.registeredSince = dateString
    }
}
