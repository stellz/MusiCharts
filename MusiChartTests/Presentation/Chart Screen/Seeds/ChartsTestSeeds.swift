//
//  ChartsTestSeeds.swift
//  MusiChartTests
//
//  Created by Stella on 31.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
@testable import MusiChart

struct ChartsTestSeeds {
    
    static let userPlayCount = 10
    static let topArtists = [Artist(name: "Morcheeba", plays: 20, imageURL: "image"), Artist(name: "Massive Attack", plays: 25, imageURL: "image")].sorted { (artist1, artist2) -> Bool in
        return artist1.plays > artist2.plays
    }
    static let overallTopArtist = topArtists.first!
    static let trackAlbumArt = "awesomeImage"
    
}
