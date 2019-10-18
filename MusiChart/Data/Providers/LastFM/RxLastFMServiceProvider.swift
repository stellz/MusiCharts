//
//  RxLastFMService.swift
//  MusiChart
//
//  Created by Stella on 18.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift

protocol RxLastFMServiceProviding {
    
    func login(name: String, password: String) -> Observable<Credentials?>
    func getUserPlaycount(userEmail: String) -> Observable<Int?>
    func getTopArtists(for username: String, period: String?, limitedTo: Int) -> Observable<[Artist]>
    func scrobbleTrack(song: String, artist: String, sessionKey: String) -> Observable<Result?>
    func loveTrack(isLoved: Bool, song: String, artist: String, sessionKey: String) -> Observable<Result?>
    func getTrackAlbumArt(queryInfo: (String, String)) -> Observable<String?>
}

final class RxLastFMServiceProvider: NSObject, RxLastFMServiceProviding {
    
    func login(name: String, password: String) -> Observable<Credentials?> {
        
        return Observable.create { observer in
            
            LastFMService.login(name: name, password: password, completion: { loginData, _ in
                if kDebugLog { print("Login Info:\(String(describing: loginData))") }
                
                guard let loginData = loginData else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                
                let sessionName = loginData.username
                let sessionKey = loginData.password
                
                // If login is successful
                LastFMService.getUserInfo(userEmail: sessionName, completion: { (user, _) in
                    
                    guard let user = user else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    if kDebugLog { print("User Info:\(user)") }
                    
                    let userData = Credentials.UserInfo(realName: user.name, registeredSince: user.registeredSince, imageUrlPath: user.imageURL)
                    let credentials = Credentials(sessionName: sessionName, sessionKey: sessionKey, userInfo: userData)
                    
                    observer.onNext(credentials)
                    observer.onCompleted()
                })
            })
            
            return Disposables.create()
        }
        
    }
    
    func getUserPlaycount(userEmail: String) -> Observable<Int?> {
        
        return Observable.create { observer in
            
            LastFMService.getUserPlaycount(userEmail: userEmail) { (playcount, error) in
                
                if error != nil {
                    observer.onNext(nil)
                } else {
                    observer.onNext(playcount)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    func getTopArtists(for username: String, period: String?, limitedTo: Int) -> Observable<[Artist]> {
        
        return Observable.create { observer in
            
            LastFMService.getTopArtists(for: username, period: period ?? LastFM.Period.overall, limit: 10, completion: { artists, _ in
                
                if kDebugLog { print("Top Artists \(period ?? LastFM.Period.overall) : \(artists)") }
                
                let topArtists = artists.prefix(limitedTo).map({ return $0 })
                
                observer.onNext(topArtists)
                observer.onCompleted()
            })

            return Disposables.create()
        }
    }
    
    func scrobbleTrack(song: String, artist: String, sessionKey: String) -> Observable<Result?> {
        
        return Observable.create { observer in
            
            LastFMService.scrobbleTrack(song: song, artist: artist, sessionKey: sessionKey, completion: { (_, error) in
                
                if let error = error {
                    observer.onNext(.error(.scrobbleFailure(error)))
                } else {
                    observer.onNext(Result.result(true))
                }
                
                observer.onCompleted()
            })
            
            return Disposables.create()
        }
    }
    
    func loveTrack(isLoved: Bool, song: String, artist: String, sessionKey: String) -> Observable<Result?> {
        
        return Observable.create { observer in
            
            LastFMService.loveTrack(love: isLoved, song: song, artist: artist, sessionKey: sessionKey, completion: { (_, error) in
                if let error = error {
                    observer.onNext(Result.error(.loveFailure(error)))
                } else {
                    observer.onNext(Result.result(true))
                }
                
                observer.onCompleted()
            })
            
            return Disposables.create()
        }
    }
    
    func getTrackAlbumArt(queryInfo: (String, String)) -> Observable<String?> {
        return Observable.create { observer in
            
            LastFMService.getTrackAlbumArt(queryInfo: queryInfo, completion: { (artURL, error) in
                
                if error != nil {
                    observer.onNext(nil)
                } else {
                    guard let artURL = artURL else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    observer.onNext(artURL)
                }
                
                observer.onCompleted()
            })
            
            return Disposables.create()
        }
    }
}
