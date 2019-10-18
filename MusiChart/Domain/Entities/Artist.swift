//
//  Artist.swift
//  MusiChart
//
//  Created by Stella on 15.07.18.
//  Copyright © 2018 Magpie Studio Ltd. All rights reserved.
//

import Foundation

struct Artist: Equatable {
    
    let name: String
    let plays: Int
    let imageURL: String

    var debugDescription: String {
        return "Name:\(name), Plays:\(plays), imageURL:\(imageURL)"
    }
    
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        return lhs.name == rhs.name
            && lhs.plays == rhs.plays
            && lhs.imageURL == rhs.imageURL
    }
    
    init(name: String, plays: Int, imageURL: String) {
        self.name = name
        self.plays = plays
        self.imageURL = imageURL
    }
    
    init(from json: [String: Any]) {
        self.name = json["name"] as? String ?? ""
        self.plays = Int(json["playcount"] as? String ?? "") ?? 0
        
        // Get the medium sized image url path and put it in its collection
        let images = json["image"] as? [Any]
        let mediumImageInfo = images?[1] as? [String: Any]
        let imageUrLPathString = mediumImageInfo?["#text"] as? String ?? ""
        self.imageURL = imageUrLPathString
    }
}
