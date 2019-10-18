//
//  SettingsViewModel.swift
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

typealias LoginData = (username: String, password: String)

protocol SettingsViewModeling {

    var username: Observable<String?> { get }
    var imgUrlPath: Observable<String?> { get }

    var audioScrobbling: Observable<Bool> { get }
    var radioScrobbling: Observable<Bool> { get }
    
    var isConnected: Observable<Bool> { get }
    var reachability: Reachability? { get }

    var saveSettingsAction: Action<Settings, Void> { get }
    var loginAction: Action<LoginData, Result?> { get }
    var logoutAction: Action<Void, Void> { get }
    
    func resetSleepTimer() -> Bool
    func updateSleepTimer(_ stringValue: String)
    
}

final class SettingsViewModel: SettingsViewModeling {
    
    private(set) var usernameBS: BehaviorSubject<String?> = BehaviorSubject(value: nil)
    var username: Observable<String?> {
        return usernameBS
            .asObservable()
            .distinctUntilChanged()
    }
    
    private(set) var imgUrlPathBS: BehaviorSubject<String?> = BehaviorSubject(value: nil)
    var imgUrlPath: Observable<String?> {
        return imgUrlPathBS
            .asObservable()
            .distinctUntilChanged()
    }

    var audioScrobbling: Observable<Bool>
    var radioScrobbling: Observable<Bool>
    
    var isConnected: Observable<Bool>
    let reachability = Reachability()
    
    let rxLastFM: RxLastFMServiceProviding
    let settingsManager: SettingsManaging
    
    let disposeBag = DisposeBag()

    init(rxLastFM: RxLastFMServiceProviding, settingsManager: SettingsManaging) {
        self.rxLastFM = rxLastFM
        self.settingsManager = settingsManager
      
        self.radioScrobbling = settingsManager
            .settingsObs
            .map { $0.scrobbling.radioEnabled }
        self.audioScrobbling = settingsManager
            .settingsObs
            .map { $0.scrobbling.audioEnabled }
        
        self.isConnected = reachability?.rx.isReachable ?? Observable.just(false)
        
        settingsManager.credentialsObs
            .map({ credentials in
                return credentials?.sessionName
            })
            .bind(to: usernameBS)
            .disposed(by: disposeBag)
        
        settingsManager.credentialsObs
            .map({ credentials in
                return credentials?.userInfo.imageUrlPath
            })
            .bind(to: imgUrlPathBS)
            .disposed(by: disposeBag)
    }
    
    lazy var saveSettingsAction = Action<Settings, Void> { [unowned self] settings in
        self.settingsManager.saveSettings(settings)
        return .empty() // Sends only onCompleted event
    }
    
    lazy var loginAction = Action <LoginData, Result?> { [unowned self] loginData in
        
        return self.rxLastFM
            .login(name: loginData.username, password: loginData.password)
            .map({ [weak self] credentials -> Result? in
                var output: Result?
                guard let self = self, let credentials = credentials else { return nil }
                self.settingsManager.saveCredentials(credentials)
                    .take(1)
                    .subscribe(onNext: { [weak self] result in
                        switch result {
                        case .result(let successful):
                            if successful {
                                self?.usernameBS.onNext(credentials.sessionName)
                                self?.imgUrlPathBS.onNext(credentials.userInfo.imageUrlPath)
                                output = .result(true)
                            } else {
                                output = .error(.failed("Couldn't save credentials"))
                            }
                        case .error(let error):
                            output = .error(.failed(error.localizedDescription))
                        }
                    }).disposed(by: self.disposeBag)
                
                return output
            }).take(1)
    }
    
    lazy var logoutAction = Action<Void, Void> { [unowned self] _ in
        self.settingsManager.removeCredentials()
        self.usernameBS.onNext("")
        self.imgUrlPathBS.onNext("")
        return .empty() // Sends only onCompleted event
    }
    
    func resetSleepTimer() -> Bool {
        return GlobalTimer.sharedTimer.sleepTime == 0.0
    }
    
    func updateSleepTimer(_ stringValue: String) {
        
        if stringValue != "Off" {
            // Convert the title to a sleep time value and start the timer
            guard let time = Double(stringValue) else { return }
            GlobalTimer.sharedTimer.startTimer(withSleepTime: time)
        } else {
            GlobalTimer.sharedTimer.stopTimer()
        }
    }
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
}
