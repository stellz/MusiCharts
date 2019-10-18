//
//  StationsManagerSpy.swift
//  MusiChartTests
//
//  Created by Stella on 19.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import XCTest
import RxSwift
@testable import MusiChart

class StationsManagerSpy: StationsManaging {
    
    var saveStationsCalled = false
    
    var stationsPS: PublishSubject<[Station]> = PublishSubject()
    var stationsObs: Observable<[Station]>
    
    init() {
        
        stationsObs = stationsPS.startWith([Station(name: "Radio Swiss Jazz", streamURL: "http://stream.m3u", imageURL: "image", desc: "jazz music")])
    }
    
    func loadStations() -> Observable<[Station]> {
        return Observable.just([Station(name: "Radio Swiss Jazz", streamURL: "http://stream.m3u", imageURL: "image", desc: "jazz music")])
    }
    
    func saveStations(_ stations: [Station]) {
        saveStationsCalled = true
    }

}
