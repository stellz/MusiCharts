//
//  SettingsRepository.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import RxSwift
import SwiftKeychainWrapper

protocol SettingsRepo {
 
    var settingsObs: Observable<Settings> { get }
    var credentilasObs: Observable<Credentials?> { get }
    
    func saveSettings(_ settings: Settings)
    func saveCredentials(_ credentials: Credentials) -> Observable<Result>
    func removeCredentials()
}

final class SettingsRepository: SettingsRepo {
 
    private var settingsBS: BehaviorSubject<Settings>
    private var credentialsBS: BehaviorSubject<Credentials?>

    init() {
        
        let userDefaults = UserDefaults.standard
        let radioScrobbling = userDefaults.bool(forKey: UserInfo.radioScrobbleKey)
        let audioScrobbling = userDefaults.bool(forKey: UserInfo.audioScrobbleKey)
        let scrobbling = Settings.Scrobbling(audioEnabled: audioScrobbling, radioEnabled: radioScrobbling)
        let settings = Settings(scrobbling: scrobbling)
        self.settingsBS = BehaviorSubject(value: settings)
        
        let sessionKey = KeychainWrapper.standard.string(forKey: UserInfo.sessionKeyKey) ?? ""
        let sessionName = KeychainWrapper.standard.string(forKey: UserInfo.sessionNameKey) ?? ""
        let realname = KeychainWrapper.standard.string(forKey: UserInfo.realnameKey) ?? ""
        let registeredSince = KeychainWrapper.standard.string(forKey: UserInfo.registeredSinceKey) ?? ""
        let imageUrlPath = KeychainWrapper.standard.string(forKey: UserInfo.imageURLPathKey) ?? ""
        let userInfo = Credentials.UserInfo(realName: realname, registeredSince: registeredSince, imageUrlPath: imageUrlPath)
        let credentials = Credentials(sessionName: sessionName, sessionKey: sessionKey, userInfo: userInfo)
        self.credentialsBS = BehaviorSubject(value: credentials)
        
        freshInstallCheck()
    }

    var settingsObs: Observable<Settings> {
        return settingsBS.asObservable()
    }
    
    var credentilasObs: Observable<Credentials?> {
        return credentialsBS.asObservable()
    }

    func saveSettings(_ settings: Settings) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(settings.scrobbling.radioEnabled, forKey: UserInfo.radioScrobbleKey)
        userDefaults.set(settings.scrobbling.audioEnabled, forKey: UserInfo.audioScrobbleKey)
        userDefaults.synchronize()
        settingsBS.onNext(settings)
    }
    
    func saveCredentials(_ credentials: Credentials) -> Observable<Result> {
        
        let result: Observable<Result>
        
        KeychainWrapper.standard.set(credentials.userInfo.realName, forKey: UserInfo.realnameKey)
        KeychainWrapper.standard.set(credentials.userInfo.registeredSince, forKey: UserInfo.registeredSinceKey)
        KeychainWrapper.standard.set(credentials.userInfo.imageUrlPath, forKey: UserInfo.imageURLPathKey)
        
        let saveSessionKey = KeychainWrapper.standard.set(credentials.sessionKey, forKey: UserInfo.sessionKeyKey)
        let saveUsername = KeychainWrapper.standard.set(credentials.sessionName, forKey: UserInfo.sessionNameKey)
        if saveSessionKey && saveUsername {
            if kDebugLog { print("Successfuly saved credentials") }
            result = Observable.just(Result.result(true))
            credentialsBS.onNext(credentials)
        } else {
            result = Observable.just(Result.result(false))
            credentialsBS.onNext(nil)
        }
        
        return result
    }
    
    func removeCredentials() {
        
        KeychainWrapper.standard.removeObject(forKey: UserInfo.sessionNameKey)
        KeychainWrapper.standard.removeObject(forKey: UserInfo.sessionKeyKey)

        KeychainWrapper.standard.removeObject(forKey: UserInfo.imageURLPathKey)
        KeychainWrapper.standard.removeObject(forKey: UserInfo.realnameKey)
        KeychainWrapper.standard.removeObject(forKey: UserInfo.registeredSinceKey)
        
        credentialsBS.onNext(nil)
    }
    
    func freshInstallCheck() {
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: "FirstInstall") == nil {
            removeCredentials()
            userDefaults.set(false, forKey: "FirstInstall")
            userDefaults.synchronize()
        }
    }

}

// MARK: Errors
enum SettingsRepoError: LocalizedError {

    case saveSettings(description: String)

    var reason: String {
        switch self {
        case .saveSettings(let reason):
            return reason
        }
    }

    var localizedDescription: String {
        return reason
    }

    var errorDescription: String? {
        return reason
    }

}

enum UserInfo {
    
    static let audioScrobbleKey = "audioScrobble"
    static let radioScrobbleKey = "radioScrobble"
    static let realnameKey = "realname"
    static let registeredSinceKey = "registeredDateString"
    static let imageURLPathKey = "imageURLPath"
    static let sessionKeyKey = "sessionKey"
    static let sessionNameKey = "sessionName"
}
