//
//  StationsViewModel.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import MediaPlayer
import RxSwift
import Reachability
import RxReachability
import RxCocoa

typealias StationData = (name: String?, url: String?)

protocol StationsViewModeling {
    
    var radioPlayer: MusiChartPlayer { get }
    var currentStation: Station? { get }
    var currentTrack: Track? { get }
    var stations: [Station] { get }
    var searchedStations: [Station] { get }
    var nowPlayingTitle: String? { get }
    
    var isConnected: Observable<Bool> { get }
    var reachability: Reachability? { get }
    
    var settingsManager: SettingsManaging { get }
    var themeManager: ThemeManaging { get }
    
    func loadStations(onStationDataLoaded: (() -> Void)?)
    func playStation(at index: Int, fromSearch: Bool)
    func playStation()
    func pauseStation()
    func addStation(with stationData: StationData)
    func removeStation(at index: Int)
    func refreshStationList()
    func updateCurrentTrack(_ track: Track)
    func updateSearchResults(searchText: String)
}

final class StationsViewModel: NSObject, StationsViewModeling {
    
    let rxLastFM: RxLastFMServiceProviding
    let stationsManager: StationsManaging
    var settingsManager: SettingsManaging
    var themeManager: ThemeManaging
    
    var radioPlayer: MusiChartPlayer
    var stations = [Station]()
    var searchedStations = [Station]()
    var currentStation: Station?
    var currentTrack: Track?
    
    var isConnected: Observable<Bool>
    let reachability = Reachability()
    
    private var settings: Settings?
    private var credentials: Credentials?
    
    let disposeBag = DisposeBag()
    
    init(rxLastFM: RxLastFMServiceProviding, stationsManager: StationsManaging, settingsManager: SettingsManaging, themeManager: ThemeManager, player: MusiChartPlayer) {
        self.rxLastFM = rxLastFM
        self.stationsManager = stationsManager
        self.settingsManager = settingsManager
        self.themeManager = themeManager
        self.radioPlayer = player
        self.isConnected = reachability?.rx.isReachable ?? Observable.just(false)
    }
    
    var nowPlayingTitle: String? {
        guard let currentStation = currentStation, let currentTrack = currentTrack else { return nil }
        if currentTrack.title.isEmpty && currentTrack.artist.isEmpty { return currentStation.stationName }
        return currentStation.stationName + ": " + currentTrack.title + " - " + currentTrack.artist
    }
    
    func loadStations(onStationDataLoaded: (() -> Void)? = {}) {
        
        configureAudioSession()
        
        //Handle AVAudioSession interruptions ( e.g. Phone call )
        NotificationCenter.default.rx.notification(AVAudioSession.interruptionNotification)
            .map({ return $0 })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] notification in
                guard let notification = notification else { return }
                self?.sessionInterrupted(notification: notification)
            }).disposed(by: disposeBag)
        
        isConnected
            .subscribe(onNext: { [weak self] isConnected in
                self?.networkConnected(connected: isConnected)
            }).disposed(by: disposeBag)
        
        settingsManager.settingsObs
            .subscribe(onNext: { [weak self] settings in
                self?.settings = settings
            }).disposed(by: disposeBag)
        
        settingsManager.credentialsObs
            .subscribe(onNext: { [weak self] credentials in
                self?.credentials = credentials
            }).disposed(by: disposeBag)
        
        stationsManager.loadStations()
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] stations in
                self?.stations = stations
                onStationDataLoaded?()
            }).disposed(by: disposeBag)
    }
    
    private func configureAudioSession() {
        // Set AVFoundation category, required for background audio
        var error: Error?
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            success = true
        } catch let error1 {
            error = error1
            success = false
        }
        if !success {
            if kDebugLog { print("Failed to set audio session category.  Error: \(String(describing: error))") }
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error2 {
            if kDebugLog { print("audioSession setActive error \(error2)") }
        }
        
        // Configure playing control for device home screen
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { _ in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: StationNotifications.stationDidPlayPause), object: nil)
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { _ in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: StationNotifications.stationDidPlayPause), object: nil)
            return .success
        }
    }
    
    // Handling AVAudio interruptions (e.g. Phone calls)
    private func sessionInterrupted(notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber else { return }
        guard let type = AVAudioSession.InterruptionType(rawValue: typeValue.uintValue) else { return }
        
        switch type {
        case .began:
            if kDebugLog { print("AVAudio interruption: began - playback should stop") }
            
            // Pause the radio station if there is one currently playing
            guard let currentTrack = currentTrack else { return }
            if currentTrack.isPlaying {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: StationNotifications.stationDidPlayPause), object: true)
            }
        case .ended:
            if kDebugLog { print("AVAudio interruption: ended - playback should resume") }
            
            guard let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                guard let currentTrack = currentTrack else { return }
                if !currentTrack.isPlaying {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: StationNotifications.stationDidPlayPause), object: false)
                }
            }
        }
    }
    
    @objc func pausePlayAction() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: StationNotifications.stationDidPlayPause), object: nil)
    }
    
    private func networkConnected(connected: Bool) {
        guard let isPlaying = currentTrack?.isPlaying else { return }
        
        if connected && isPlaying {
            currentTrack = Track()
            stationDidChange(reconnected: true)
            playStation()
        } else if isPlaying {
            radioPlayer.pause()
        }
    }
    
    func playStation(at index: Int, fromSearch: Bool) {
        if fromSearch {
            guard searchedStations.indices.contains(index) else { return }
            let radioStation = searchedStations[index]
            currentStation = radioStation
        } else {
            guard stations.indices.contains(index) else { return }
            let radioStation = stations[index]
            currentStation = radioStation
        }
        
        currentTrack = Track()
        stationDidChange(reconnected: false)
        playStation()
    }
    
    func playStation() {
        currentTrack?.isPlaying = true
        radioPlayer.play()
    }
    
    func pauseStation() {
        currentTrack?.isPlaying = false
        radioPlayer.pause()
    }
    
    private func stationDidChange(reconnected: Bool) {
        
        guard let currentStation = currentStation, let streamURL = URL(string: currentStation.stationStreamURL) else {
            if kDebugLog { print("Stream Error") }
            return
        }
        
        // If the stream is OK create and setup a stream object
        let streamItem = MusiChartPlayerItem(url: streamURL as URL)
        streamItem.delegate = self
        // Prevent the player from "stalling"
        self.radioPlayer.replaceCurrentItem(with: streamItem)
        self.radioPlayer.play()
        
        currentTrack?.isPlaying = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: StationNotifications.stationDidChange), object: reconnected)
    }
    
    func addStation(with stationData: StationData) {
        guard let stationName = stationData.name, let stationURL = stationData.url else { return }
        let station = Station.init(name: stationName, streamURL: stationURL, imageURL: "", desc: "User station")
        stations.append(station)
        stationsManager.saveStations(stations)
    }
    
    func removeStation(at index: Int) {
        stations.remove(at: index)
        stationsManager.saveStations(stations)
    }
    
    func refreshStationList() {
        stations.removeAll(keepingCapacity: false)
        loadStations()
    }
    
    func updateSearchResults(searchText: String) {
        searchedStations.removeAll(keepingCapacity: false)
        
        searchedStations = stations.filter { station in
            return station.stationName.range(of: searchText, options: [.caseInsensitive]) != nil
        }
    }
    
    func updateCurrentTrack(_ track: Track) {
        currentTrack?.artworkURL = track.artworkURL
        currentTrack?.artworkImage = track.artworkImage
        updateLockScreen()
    }
    
    private func updateLockScreen() {
        
        guard let currentTrack = currentTrack, let artworkImage = currentTrack.artworkImage else { return }
        let albumArtwork = MPMediaItemArtwork.init(boundsSize: currentTrack.artworkImage!.size, requestHandler: { _ -> UIImage in
            return artworkImage
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: currentTrack.artist,
            MPMediaItemPropertyTitle: currentTrack.title,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
    }
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }

}

// MARK: - MusiChartPlayerItem Delegate (for metadata change)

extension StationsViewModel: MusiChartPlayerItemDelegate {
    
    func playerItem(playerItem: MusiChartPlayerItem, didUpdateMetadata metaData: [AVMetadataItem]?) {
      
        guard let metaDatas = metaData, let metaData = metaDatas.first?.value as? String else { return }
        
        var stringParts = [String]()
        
        if metaData.range(of: " - ") != nil {
            stringParts = metaData.components(separatedBy: " - ")
        } else {
            stringParts = metaData.components(separatedBy: "-")
        }
        
        // Update the currentTrack object with the new artist and song info
        let currentSongName = currentTrack?.title
        
        currentTrack?.artist = stringParts[0].decodeAll()
        currentTrack?.title = stringParts[0].decodeAll()
        
        if stringParts.count > 1 {
            currentTrack?.title = stringParts[1].decodeAll()
        }
        
        guard let currentTrack = currentTrack, let currentStation = currentStation else { return }
        
        if currentTrack.artist.isEmpty && currentTrack.title.isEmpty {
            self.currentTrack?.artist = currentStation.stationDesc
            self.currentTrack?.title = currentStation.stationName
        } else {
            self.currentTrack?.artist = currentTrack.artist.refineForLastFM() ?? ""
            self.currentTrack?.title = currentTrack.title.refineForLastFM() ?? ""
        }
        
        guard currentSongName != currentTrack.title else { return }
        
        if kDebugLog { print("METADATA artist: \(currentTrack.artist) | title: \(currentTrack.title)") }
        
        scrobbleTrack()
        
        DispatchQueue.main.async {
            self.updateLockScreen()
            NotificationCenter.default.post(name: NSNotification.Name(SongNotification.currentSongChanged), object: currentTrack)
        }
    }
    
    private func scrobbleTrack() {
        
        guard let credentials = credentials, let audioScrobblingEnabled = settings?.scrobbling.audioEnabled, audioScrobblingEnabled == true else { return }
        
        //We are checking for duplicte scrobbles, because sometimes the radio station itself streams promo messages
        guard let currentStation = currentStation, let currentTrack = currentTrack, currentStation.stationName != currentTrack.artist else { return }
        
        guard let radioScrobblingEnabled = settings?.scrobbling.radioEnabled else { return }
        
        if radioScrobblingEnabled {
            //We refine the strings because the URL in the API call must escape characters like '&'
            guard let refinedStation = currentStation.stationName.refineForLastFM() else { return }
            guard let refinedDesc = currentStation.stationDesc.refineForLastFM() else { return }
            
            let radioScrobbleObs = rxLastFM.scrobbleTrack(song: refinedDesc, artist: refinedStation, sessionKey: credentials.sessionKey)
            
            let audioScrobbleObs = rxLastFM.scrobbleTrack(song: currentTrack.title, artist: currentTrack.artist, sessionKey: credentials.sessionKey)
            
            Observable.combineLatest(audioScrobbleObs, radioScrobbleObs, resultSelector: { audioScrobbleResult, radioScrobbleResult in
                return (audioScrobbleResult: audioScrobbleResult, radioScrobbleResult: radioScrobbleResult)
            })
                .asDriver(onErrorJustReturn: nil)
                .drive(onNext: { result in
                    guard let audioScrobbleResult = result?.audioScrobbleResult?.resultValue, let radioScrobbleResult = result?.radioScrobbleResult?.resultValue else { return }
                    
                    if audioScrobbleResult || radioScrobbleResult {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
                            let notifictionName = Notification.Name(rawValue: LastFMNotifications.didScrobbleTrack)
                            NotificationCenter.default.post(name: notifictionName, object: nil)
                        })
                    }
                })
                .disposed(by: disposeBag)
        } else {
            //"Scrobble" the actual track only
            rxLastFM.scrobbleTrack(song: currentTrack.title, artist: currentTrack.artist, sessionKey: credentials.sessionKey)
                .asDriver(onErrorJustReturn: nil)
                .drive(onNext: { result in
                    guard let result = result else { return }
                    switch result {
                    case .result(let successful):
                        if successful {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
                                let notifictionName = Notification.Name(rawValue: LastFMNotifications.didScrobbleTrack)
                                NotificationCenter.default.post(name: notifictionName, object: nil)
                            })
                        }
                    case .error(let error):
                        print(error.localizedDescription)
                    }
                }).disposed(by: disposeBag)
        }
    }
}
