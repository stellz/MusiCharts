//
//  StationsManager.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift

protocol StationsManaging {
    
    var stationsObs: Observable<[Station]> { get }
    
    func loadStations() -> Observable<[Station]>
    func saveStations(_ stations: [Station])
}

final class StationsManager: StationsManaging {
    
    let stationsRepo: StationsRepo
    
    init(stationsRepo: StationsRepo) {
        self.stationsRepo = stationsRepo
    }
    
    var stationsObs: Observable<[Station]> {
        return stationsRepo.stationsObs
    }
    
    func loadStations() -> Observable<[Station]> {
        return stationsRepo.loadStationsFromDisk()
    }
    
    func saveStations(_ stations: [Station]) {
        stationsRepo.saveStationsToDisk(stations)
    }
}
