//
//  NowPlayingViewModel.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift
import Action

protocol NowPlayingViewModelDelegate: class {
    
    func nowPlayingViewModel(_ nowPlayingViewModel: NowPlayingViewModeling, didUpdateArtwork track: Track?)
}

protocol NowPlayingViewModeling {
    
    var delegate: NowPlayingViewModelDelegate? { get set }
    
    var currentStation: Station { get }
    var currentTrack: Track { get }
    
    var getAlbumArtURL: Action<Track, String> { get }
    
    func loveTrack(_ isLoved: Bool, song: String, artist: String)
    func loadImageWithURL(url: URL, callback: @escaping (UIImage) -> Void)
}

final class NowPlayingViewModel: NowPlayingViewModeling {
    
    weak var delegate: NowPlayingViewModelDelegate?
    
    var currentStation: Station
    var currentTrack: Track
    
    let rxLastFM: RxLastFMServiceProviding
    let settingsManager: SettingsManaging
    
    private var credentials: Credentials?
    private var settings: Settings?
    
    let disposeBag = DisposeBag()
    
    init(rxLastFM: RxLastFMServiceProviding,
         settingsManager: SettingsManaging,
         currentStation: Station,
         currentTrack: Track) {
        
        self.rxLastFM = rxLastFM
        self.settingsManager = settingsManager
        self.currentStation = currentStation
        self.currentTrack = currentTrack
        
        settingsManager.credentialsObs
            .subscribe(onNext: { [weak self] credentials in
                self?.credentials = credentials
            }).disposed(by: disposeBag)
        
        settingsManager.settingsObs
            .subscribe(onNext: { [weak self] settings in
                self?.settings = settings
            }).disposed(by: disposeBag)
    }
    
    lazy var getAlbumArtURL = Action <Track, String> { [unowned self] track in
        
        self.currentTrack = track
        let queryInfo = (track.artist, track.title)
        
        return self.rxLastFM.getTrackAlbumArt(queryInfo: queryInfo)
            .map({ [weak self] artUrl in
                
                self?.currentTrack.artworkLoaded = true
                guard let artURL = artUrl else {
                    self?.currentTrack.artworkURL = self?.currentStation.stationImageURL ?? ""
                    return self?.currentStation.stationImageURL ?? ""
                }
                // LastFM image found!
                self?.currentTrack.artworkURL = artURL
                return artURL
            })
    }
    
    func loveTrack(_ isLoved: Bool, song: String, artist: String) {
        
        print (settings.debugDescription)
        
        guard let scrobblingEnabled = settings?.scrobbling.audioEnabled, scrobblingEnabled, let sessionKey = credentials?.sessionKey else { return }
        
        rxLastFM.loveTrack(isLoved: isLoved, song: song, artist: artist, sessionKey: sessionKey)
            .subscribe(onNext: { result in
                guard let result = result else { return }
                switch result {
                case .result(let successful):
                    if successful {
                        if kDebugLog { print("show bezel for loved track") }
                    }
                case .error(let error):
                    print(error.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }
    
    func loadImageWithURL(url: URL, callback: @escaping (UIImage) -> Void) {
        
        let downloadTask = URLSession.shared.downloadTask(with: url, completionHandler: { [weak self] url, _, error in
            
            guard let url = url, error == nil else { return }
            
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data), let self = self else { return }
                self.currentTrack.artworkImage = image
                self.currentTrack.artworkLoaded = true
                
                self.delegate?.nowPlayingViewModel(self, didUpdateArtwork: self.currentTrack)
                
                callback(image)
            } catch {
                print(error.localizedDescription)
            }
            
        })
        
        downloadTask.resume()
    }
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
}
