//
//  ChartsViewModelSpy.swift
//  MusiChartTests
//
//  Created by Stella on 31.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift
import Reachability
import Action
@testable import MusiChart

class ChartsViewModelSpy: ChartsViewModeling {
    
    var username: String?
    
    var registeredSince: Observable<String?>
    
    var realName: Observable<String?>
    
    var isConnected: Observable<Bool>
    
    var reachability: Reachability? = Reachability()
    
    lazy var updatePlaycountAction = Action<String, String?> { [weak self] username in
        guard let disposeBag = self?.disposeBag else { return .empty() }
        self?.updatePlaycountActionCalled = true
        self?.getPlayCount(for: username)
            .subscribe(onNext: { playcount in
                if let playcount = playcount {
                    self?.playcountBS.onNext(playcount)
                }
            }).disposed(by: disposeBag)

        return .just("")
    }
    
    lazy var getTopArtistsAction = Action<UserData, [ArtistCellViewModel]?> { [weak self] userData in
        guard let self = self else { return Observable.just(nil) }
        return self.getTopArtists(for: userData.username, period: userData.period, limitedTo: userData.limit)
    }
    
    lazy var getOverallTopArtistAction = Action<String, Artist?> { [weak self] username in
        guard let self = self else { return Observable.just(nil) }
        return self.getOverallTopArtist(for: username)
    }
    
    let settingsManager: SettingsManaging
    let stationsManager: StationsManaging
    let rxLastFM: RxLastFMServiceProviding
    
    var updatePlaycountActionCalled = false
    var getTopArtistsActionCalled = false
    var getOverallTopArtistCalled = false
    
    private var stations: [Station]?
    
    let disposeBag = DisposeBag()
    
    init(rxLastFM: RxLastFMServiceProviding, settingsManager: SettingsManaging, stationsManager: StationsManaging) {
        
        self.rxLastFM = rxLastFM
        self.settingsManager = settingsManager
        self.stationsManager = stationsManager
        
        if let reachability = reachability {
            isConnected = reachability.rx.isReachable
        } else {
            isConnected = Observable.just(false)
        }
        
        let credentialsObs = settingsManager.credentialsObs
        
        registeredSince = credentialsObs
            .map({ credentials in
                guard let registeredDate = credentials?.userInfo.registeredSince else {
                    return nil
                }
                return "plays since" + "\(registeredDate)"
            })
        
        realName = credentialsObs
            .map({ credentials in
                guard let realName = credentials?.userInfo.realName, !realName.isEmpty else {
                    return credentials?.sessionName
                }
                return credentials?.userInfo.realName
            })
        
        credentialsObs
            .subscribe(onNext: { [weak self] credentials in
                self?.username = credentials?.sessionName
            }).disposed(by: disposeBag)
        
        stationsManager.loadStations()
            .subscribe(onNext: { [weak self] stations in
                self?.stations = stations
            }).disposed(by: disposeBag)
        
        credentialsObs.subscribe(onNext: { [weak self] credentials in
            self?.usernameBS.onNext(credentials?.sessionName)
        }).disposed(by: disposeBag)
        
        usernameObs
            .flatMap({ [weak self] name -> Observable<Int?> in
                guard let name = name, let playcount = self?.getPlayCount(for: name) else {
                    return Observable.just(nil)
                }
                return playcount
            }).subscribe(onNext: { [weak self] playcount in
                self?.playcountBS.onNext(playcount)
            }).disposed(by: disposeBag)
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
    private func getPlayCount(for username: String) -> Observable<Int?> {
        
        return rxLastFM
            .getUserPlaycount(userEmail: username)
    }
    
    private func getTopArtists(for username: String, period: String, limitedTo: Int) -> Observable<[ArtistCellViewModel]?> {
        
        getTopArtistsActionCalled = true
        
        return rxLastFM
            .getTopArtists(for: username, period: period, limitedTo: 5)
            .map({ artists in
                artists.map({ [weak self] artist in
                    var artist = artist
                    if artist.imageURL.isEmpty {
                        if let stations = self?.stations {
                            // Check if the station is in that list and use its image URL
                            for station in stations where station.stationName == artist.name {
                                artist = Artist(name: artist.name, plays: artist.plays, imageURL: station.stationImageURL)
                            }
                        }
                    }
                    return ArtistCellViewModel(artist: artist)
                })
            })
    }
    
    private func getOverallTopArtist(for username: String) -> Observable<Artist?> {
        
        getOverallTopArtistCalled = true
        
        return rxLastFM
            .getTopArtists(for: username, period: nil, limitedTo: 1)
            .map({ artists in
                artists.first
            })
    }
}
