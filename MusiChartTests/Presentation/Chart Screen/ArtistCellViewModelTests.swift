//
//  ArtistCellViewModelTests.swift
//  MusiChartTests
//
//  Created by Stella on 18.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import XCTest
@testable import MusiChart

class ArtistCellViewModelTests: XCTestCase {
    
    func testArtistCellViewModel() {
        
        let artist = Artist(name: "James Brown", plays: 2, imageURL: "image")
        let artistCellViewModel = ArtistCellViewModel(artist: artist)
        
        XCTAssertEqual(artist.name, artistCellViewModel.name)
        XCTAssertEqual(artist.plays, artistCellViewModel.plays)
        XCTAssertEqual(artist.imageURL, artistCellViewModel.imageURL)
    }
}
