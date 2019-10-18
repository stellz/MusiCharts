//
//  RxLastFMSpy.swift
//  MusiChartTests
//
//  Created by Stella on 18.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import XCTest
import RxSwift
@testable import MusiChart

class RxLastFMServiceProviderSpy: RxLastFMServiceProviding {
    
    func login(name: String, password: String) -> Observable<Credentials?> {
        return Observable.just(Credentials(sessionName: "some_usrname", sessionKey: "some_key", userInfo:
            Credentials.UserInfo(realName: "Real name", registeredSince: "01.01.2018", imageUrlPath: "image")))
    }
    
    func getUserPlaycount(userEmail: String) -> Observable<Int?> {
        return Observable.just(ChartsTestSeeds.userPlayCount)
    }
    
    func getTopArtists(for username: String, period: String?, limitedTo: Int) -> Observable<[Artist]> {
        return Observable.just(ChartsTestSeeds.topArtists)
    }
    
    func scrobbleTrack(song: String, artist: String, sessionKey: String) -> Observable<Result?> {
        return Observable.just(Result.result(true))
    }
    
    func loveTrack(isLoved: Bool, song: String, artist: String, sessionKey: String) -> Observable<Result?> {
        return Observable.just(Result.result(true))
    }
    
    func getTrackAlbumArt(queryInfo: (String, String)) -> Observable<String?> {
        return Observable.just(ChartsTestSeeds.trackAlbumArt)
    }
        
}
