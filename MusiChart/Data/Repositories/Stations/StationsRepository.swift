//
//  StationsRepository.swift
//  MusiChart
//
//  Created by Stella on 4.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift

protocol StationsRepo {
    
    var stationsObs: Observable<[Station]> { get }
    
    func loadStationsFromDisk() -> Observable<[Station]>
    func saveStationsToDisk(_ stations: [Station])
}

final class StationsRepository: StationsRepo {
    
    private var stationsBS: BehaviorSubject<[Station]> = BehaviorSubject(value: [])
    
    let stationsProvider: StationsProviding
    
    init(stationsProvider: StationsProviding) {
        self.stationsProvider = stationsProvider
    }
    
    var stationsObs: Observable<[Station]> {
        return stationsBS.asObservable()
    }
    
    func saveStationsToDisk(_ stations: [Station]) {
        
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(stations, forKey: "userStations")
        archiver.finishEncoding()
        data.write(toFile: dataFilePath(), atomically: true)
    }
    
    func loadStationsFromDisk() -> Observable<[Station]> {
        
        var stations = loadUserStations()
        
        // If there are user stations don't load remote stations
        if !stations.isEmpty {
            stationsBS.onNext(stations)
            return Observable.just(stations)
        }
        
        return Observable.create { [weak self] observer in
            
            self?.stationsProvider.getStationDataWithSuccess { (data) in
                if kDebugLog { print("Stations JSON Found") }
                
                guard let data = data else { return }
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let jsonDictionary = jsonData as? [String: Any],
                        let stationArray = jsonDictionary["station"] as? [[String: Any]] else {
                            return
                    }
                    stations = stationArray.map({ stationInfo in
                        return Station.parseStation(from: stationInfo)
                    })
                    
                    self?.saveStationsToDisk(stations)
                    self?.stationsBS.onNext(stations)
                    
                    observer.onNext(stations)
                    observer.onCompleted()
                    
                } catch let parsingError {
                    print("Parsing Error: \(parsingError)")
                }
            }
            
            return Disposables.create()
        }
    }
    
    private func loadUserStations() -> [Station] {
        
        var stations = [Station]()
        
        let path = dataFilePath()
        let defaultManager = FileManager()
        if defaultManager.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            do {
                let data = try Data(contentsOf: url)
                let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                if let userStations = try unarchiver.decodeTopLevelObject(forKey: "userStations") as? [Station] {
                    stations = userStations
                }
                unarchiver.finishDecoding()
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return stations
    }
    
    private func dataFilePath () -> String {
        return documentsDirectory().appendingFormat("/userStations.plist")
    }
    
    private func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                        .userDomainMask, true)
        let documentsDirectory = paths.first!
        return documentsDirectory
    }
}
