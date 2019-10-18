//
//  ChartsViewModel.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift
import Action
import Reachability
import RxReachability

typealias UserData = (username: String, period: String, limit: Int)

protocol ChartsViewModeling {

    var username: String? { get }
    var usernameObs: Observable<String?> { get }
    var playcount: Observable<String?> { get }
    var registeredSince: Observable<String?> { get }
    var realName: Observable<String?> { get }
    var isConnected: Observable<Bool> { get }
    var reachability: Reachability? { get }
    
    var updatePlaycountAction: Action<String, String?> { get }
    var getTopArtistsAction: Action<UserData, [ArtistCellViewModel]?> { get }
    var getOverallTopArtistAction: Action<String, Artist?> { get }
   
}

final class ChartsViewModel: ChartsViewModeling {

    let settingsManager: SettingsManaging
    let stationsManager: StationsManaging
    let rxLastFM: RxLastFMServiceProviding
  
    var username: String?
    var registeredSince: Observable<String?>
    var realName: Observable<String?>
    
    var isConnected: Observable<Bool>
    let reachability = Reachability()
    
    private var stations: [Station]?
    
    let disposeBag = DisposeBag()
    
    init(rxLastFM: RxLastFMServiceProviding, settingsManager: SettingsManaging, stationsManager: StationsManaging) {
        
        self.rxLastFM = rxLastFM
        self.settingsManager = settingsManager
        self.stationsManager = stationsManager
        
        isConnected = reachability?.rx.isReachable ?? Observable.just(false)
        
        registeredSince = settingsManager.credentialsObs
            .map({ credentials in
                guard let registeredDate = credentials?.userInfo.registeredSince else {
                    return nil
                }
                return "plays since" + "\(registeredDate)"
            })
        
        realName = settingsManager.credentialsObs
            .map({ credentials in
                guard let realName = credentials?.userInfo.realName, !realName.isEmpty else {
                    return credentials?.sessionName
                }
                return credentials?.userInfo.realName
            })
        
        stationsManager.loadStations()
            .subscribe(onNext: { [weak self] stations in
                self?.stations = stations
            }).disposed(by: disposeBag)
        
        settingsManager.credentialsObs
            .subscribe(onNext: { [weak self] credentials in
                self?.username = credentials?.sessionName
            }).disposed(by: disposeBag)
        
        settingsManager.credentialsObs
            .map({ credentials in
                return credentials?.sessionName
            })
            .bind(to: usernameBS)
            .disposed(by: disposeBag)
        
        usernameObs
            .flatMap({ name -> Observable<Int?> in
                guard let name = name, !name.isEmpty else {
                    return Observable.just(nil)
                }
                return rxLastFM
                    .getUserPlaycount(userEmail: name)
            })
            .bind(to: playcountBS)
            .disposed(by: disposeBag)
    }
    
    private(set) var usernameBS: BehaviorSubject<String?> = BehaviorSubject(value: nil)
    var usernameObs: Observable<String?> {
        return usernameBS
            .asObservable()
            .distinctUntilChanged()
    }
    
    private(set) var playcountBS: BehaviorSubject<Int?> = BehaviorSubject(value: nil)
    var playcount: Observable<String?> {
        return playcountBS
            .asObservable()
            .map({ guard let playcount = $0 else { return nil }
                return String(playcount)
            })
            .distinctUntilChanged()
    }
    
    lazy var updatePlaycountAction = Action<String, String?> { [unowned self] username in
        return self.rxLastFM
            .getUserPlaycount(userEmail: username)
            .filter({ $0 != nil })
            .map({ guard let playcount = $0 else { return nil }
                return String(playcount)
            })
    }
    
    lazy var getTopArtistsAction = Action<UserData, [ArtistCellViewModel]?> { [unowned self] userData in
        return self.rxLastFM
            .getTopArtists(for: userData.username, period: userData.period, limitedTo: userData.limit)
            .map({ artists in
                artists.map({ [weak self] artist in
                    var artist = artist
                    if artist.imageURL.isEmpty, let stations = self?.stations {
                        // Check if the station is in that list and use its image URL
                        for station in stations where station.stationName == artist.name {
                            artist = Artist(name: artist.name, plays: artist.plays, imageURL: station.stationImageURL)
                        }
                    }
                    return ArtistCellViewModel(artist: artist)
                })
            })
    }
    
    lazy var getOverallTopArtistAction = Action<String, Artist?> { [unowned self] username in
        return self.rxLastFM
            .getTopArtists(for: username, period: nil, limitedTo: 1)
            .map({ artists in
                artists.first
            })
    }
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
    
}
