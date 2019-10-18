//
//  StationCellViewModel.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation

struct StationCellViewModel {
    
    var stationName: String
    var stationDescription: String
    var imageURL: String
    
    init(station: Station) {
        
        self.stationName = station.stationName
        self.stationDescription = station.stationDesc
        self.imageURL = station.stationImageURL
    }
}
