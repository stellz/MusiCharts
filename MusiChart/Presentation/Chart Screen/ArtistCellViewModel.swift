//
//  ArtistViewModel.swift
//  MusiChart
//
//  Created by Stella on 17.06.18.
//  Copyright © 2018 Magpie Studio Ltd. All rights reserved.
//

import Foundation

struct ArtistCellViewModel {
    
    var name: String
    var plays: Int
    var imageURL: String

    init(artist: Artist) {
        
        self.name = artist.name
        self.imageURL = artist.imageURL
        self.plays = artist.plays
    }

    var debugDescription: String {
        return "Name:\(name), Plays:\(plays), imageURL:\(imageURL)"
    }
}
