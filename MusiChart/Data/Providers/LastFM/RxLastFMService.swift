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
    func loginLastFM(email: String, password: String) -> Observable<Credentials?>
    func getUserPlaycount(userEmail: String) -> Observable<Int?>
    func getTopArtists(for username: String, period: String?, limitedTo: Int) -> Observable<[Artist]>
}

class RxLastFMServiceProvider: NSObject, RxLastFMServiceProviding {
    
    func loginLastFM(email: String, password: String) -> Observable<Credentials?> {
        return Observable.create { observer in
            LastFMService.loginLastFMWithCompletion(userEmail: email, userPassword: password, completion: { jsonData, _ in
                if kDebugLog { print("Login Info:\(jsonData)") }
                
                let session = jsonData["session"]
                
                guard let sessionKey = session["key"].string, let sessionName = session["name"].string else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                // If login is successful
                LastFMService.getUserInfoWithCompletion(userEmail: sessionName, completion: { (jsonData, _) in
                    
                    if kDebugLog { print("User Info:\(jsonData)") }
                    
                    let user = jsonData["user"]
                    let name = user["realname"].string ?? ""
                    let registeredInfo = user["registered"]
                    let registeredTimeString = registeredInfo["unixtime"].doubleValue
                    let registeredTime = NSDate.init(timeIntervalSince1970: registeredTimeString)
                    let description = registeredTime.description(with: NSLocale(localeIdentifier: "en_US"))
                    let mainPart = description.components(separatedBy: "at")[0]
                    let components = mainPart.components(separatedBy: ",")
                    var dateString = ""
                    if components.count >= 3 {
                        dateString = components[1] + "," + components[2]
                        if kDebugLog { print("Registered since:", dateString) }
                    }
                    let images = user["image"].arrayValue
                    let imageDict = images.last
                    guard let imageURLPath = imageDict?["#text"].stringValue else { return }
                    
                    let userData = Credentials.UserInfo(realName: name, registeredSince: dateString, imageUrlPath: imageURLPath)
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
            LastFMService.getUserPlaycountWithCompletion(userEmail: userEmail) { (playcount, error) in
                
                if error != nil {
                    observer.onNext(nil)
                } else {
                    if kDebugLog { print("User overll playcount: \(playcount)") }
                    observer.onNext(playcount)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    func getTopArtists(for username: String, period: String?, limitedTo: Int) -> Observable<[Artist]> {
        
        return Observable.create { observer in
            
            LastFMService.getTopArtists(forUser: username, period: period ?? LastFM.Period.overall, limit: 10, completion: { artists, _ in
                
                if kDebugLog { print("Top Artists for last 7 days:\(artists)") }
                
                let topArtists = artists.prefix(limitedTo).map({ return $0 })
                
                observer.onNext(topArtists)
                observer.onCompleted()
            })

            return Disposables.create()
        }
    }
}
