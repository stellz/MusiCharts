//
//  SettingsManagerSpy.swift
//  MusiChartTests
//
//  Created by Stella on 19.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import XCTest
import RxSwift
@testable import MusiChart

class SettingsManagerSpy: SettingsManaging {
    
    var saveSettingsCalled = false
    var removeCredentialsCalled = false
    
    var settingsPS: PublishSubject<Settings> = PublishSubject()
    var settingsObs: Observable<Settings>
    
    var scrobblingSettingsPS: PublishSubject<Settings.Scrobbling> = PublishSubject()
    var scrobblingSettingsObs: Observable<Settings.Scrobbling>
    
    var credentialsPS: PublishSubject<Credentials?> = PublishSubject()
    var credentialsObs: Observable<Credentials?>

    var userInfoPS: PublishSubject<Credentials.UserInfo?> = PublishSubject()
    var userInfoObs: Observable<Credentials.UserInfo?>
    
    init() {
        
        self.settingsObs = settingsPS.startWith(Settings(scrobbling: Settings.Scrobbling(audioEnabled: true, radioEnabled: true))).share(replay: 1, scope: .whileConnected)
        self.scrobblingSettingsObs = scrobblingSettingsPS.startWith(Settings.Scrobbling(audioEnabled: true, radioEnabled: true)).share(replay: 1, scope: .whileConnected)
        self.credentialsObs = credentialsPS.startWith(Credentials(sessionName: "user", sessionKey: "key", userInfo:
            Credentials.UserInfo(realName: "realName", registeredSince: "01.01.2019", imageUrlPath: "imge"))).share(replay: 1, scope: .whileConnected)
        self.userInfoObs = userInfoPS.startWith(Credentials.UserInfo(realName: "realName", registeredSince: "01.01.2019", imageUrlPath: "image")).share(replay: 1, scope: .whileConnected)
    }
    
    func saveSettings(_ settings: Settings) {
        saveSettingsCalled = true
    }
    
    func saveCredentials(_ credentials: Credentials) -> Observable<Result> {
        return Observable.just(Result.result(true))
    }
    
    func removeCredentials() {
        removeCredentialsCalled = true
    }
    
}
