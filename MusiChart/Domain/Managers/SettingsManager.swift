//
//  SettingsManager.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift

protocol SettingsManaging {
    
    var settingsObs: Observable<Settings> { get }
    var scrobblingSettingsObs: Observable<Settings.Scrobbling> { get }
    var credentialsObs: Observable<Credentials?> { get }
    var userInfoObs: Observable<Credentials.UserInfo?> { get }

    func saveSettings(_ settings: Settings)
    func saveCredentials(_ credentials: Credentials) -> Observable<Result>
    func removeCredentials()
}

final class SettingsManager: SettingsManaging {

    private var settingsRepo: SettingsRepo

    init(settingsRepo: SettingsRepo) {
        self.settingsRepo = settingsRepo
    }

    var settingsObs: Observable<Settings> {
        return settingsRepo.settingsObs
    }
    
    var credentialsObs: Observable<Credentials?> {
        return settingsRepo.credentilasObs
    }

    var scrobblingSettingsObs: Observable<Settings.Scrobbling> {
        return self.settingsObs.map { settings in
            return settings.scrobbling
            }
            .distinctUntilChanged({ lhs, rhs in
                return lhs.radioEnabled == rhs.radioEnabled && lhs.audioEnabled == rhs.audioEnabled
            })
    }

    var userInfoObs: Observable<Credentials.UserInfo?> {
        return self.credentialsObs.map { credentials in
            return credentials?.userInfo
            }
            .distinctUntilChanged({ lhs, rhs in
                return lhs?.realName == rhs?.realName && lhs?.registeredSince == rhs?.registeredSince && lhs?.imageUrlPath == rhs?.imageUrlPath
            })
    }

    func saveSettings(_ settings: Settings) {
        settingsRepo.saveSettings(settings)
    }
    
    func saveCredentials(_ credentials: Credentials) -> Observable<Result> {
        return settingsRepo.saveCredentials(credentials)
    }
    
    func removeCredentials() {
        return settingsRepo.removeCredentials()
    }
}
