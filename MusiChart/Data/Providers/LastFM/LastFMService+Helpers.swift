//
//  LastFMService+Helpers.swift
//  MusiChart
//
//  Created by Stella on 13.04.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation

typealias ServiceResponse = ([String: Any]?, Error?) -> Void

enum LastFM {
    
    // GET AN API KEY FROM LASTFM
    // Visit: http://www.last.fm/api
    
    static let apiKey    = "yourApiKey"
    static let apiSecret = "yourApiSecret"
    
    static let baseUrlString = "https://ws.audioscrobbler.com/2.0/"
    
    enum Period {
        static let week = "7day"
        static let oneMonth = "1month"
        static let threeMonth = "3month"
        static let sixMonth = "6month"
        static let year = "12month"
        static let overall = "overall"
    }
    
    enum Method {
        static let trackGetInfo = "track.getInfo"
        static let authGetMobileSession = "auth.getMobileSession"
        static let userGetInfo = "user.getInfo"
        static let trackScrobble = "track.scrobble"
        static let userGetTopArtists = "user.getTopArtists"
        static let trackLove = "track.love"
        static let trackUnlove = "track.unlove"
    }
    
    enum URLData {
        
        static let scheme = "https"
        static let host = "ws.audioscrobbler.com"
        static let path = "/2.0/"
        static let format = "json"
        
    }
    
    enum Query {
        
        static let method = "method"
        static let username = "username"
        static let password = "password"
        static let apiKey = "api_key"
        static let apiSignature = "api_sig"
        static let format = "format"
        static let user = "user"
        static let artist = "artist"
        static let track = "track"
        static let timestamp = "timestamp"
        static let sessionKey = "sk"
        static let period = "period"
        static let limit = "limit"
    }
}

struct Endpoint {
    
    let path: String
    let queryItems: [URLQueryItem]
    
    var url: URL? {
        
        var components = URLComponents()
        components.scheme = LastFM.URLData.scheme
        components.host = LastFM.URLData.host
        components.path = path
        components.queryItems = queryItems
        
        return components.url
    }
    
    static func login(username: String,
                      password: String,
                      apiSignature: String) -> Endpoint {
        return Endpoint(
            path: LastFM.URLData.path,
            queryItems: [
                URLQueryItem(name: LastFM.Query.method, value: LastFM.Method.authGetMobileSession),
                URLQueryItem(name: LastFM.Query.username, value: username),
                URLQueryItem(name: LastFM.Query.password, value: password),
                URLQueryItem(name: LastFM.Query.apiKey, value: LastFM.apiKey),
                URLQueryItem(name: LastFM.Query.apiSignature, value: apiSignature),
                URLQueryItem(name: LastFM.Query.format, value: LastFM.URLData.format)
            ]
        )
    }
    
    static func userInfo(user: String) -> Endpoint {
        return Endpoint(
            path: LastFM.URLData.path,
            queryItems: [
                URLQueryItem(name: LastFM.Query.method, value: LastFM.Method.userGetInfo),
                URLQueryItem(name: LastFM.Query.user, value: user),
                URLQueryItem(name: LastFM.Query.apiKey, value: LastFM.apiKey),
                URLQueryItem(name: LastFM.Query.format, value: LastFM.URLData.format)
            ]
        )
    }
    
    static func scrobbleTrack(artist: String,
                              track: String,
                              timestamp: String,
                              sessionKey: String,
                              apiSignature: String) -> Endpoint {
        return Endpoint(
            path: LastFM.URLData.path,
            queryItems: [
                URLQueryItem(name: LastFM.Query.method, value: LastFM.Method.trackScrobble),
                URLQueryItem(name: LastFM.Query.artist, value: artist),
                URLQueryItem(name: LastFM.Query.track, value: track),
                URLQueryItem(name: LastFM.Query.timestamp, value: timestamp),
                URLQueryItem(name: LastFM.Query.apiKey, value: LastFM.apiKey),
                URLQueryItem(name: LastFM.Query.sessionKey, value: sessionKey),
                URLQueryItem(name: LastFM.Query.apiSignature, value: apiSignature),
                URLQueryItem(name: LastFM.Query.format, value: LastFM.URLData.format)
            ]
        )
    }
    
    static func topArtists(user: String,
                           period: String,
                           limit: String?) -> Endpoint {
        
        var endpoint: Endpoint
        
        if limit != nil {
            endpoint = Endpoint(
                path: LastFM.URLData.path,
                queryItems: [
                    URLQueryItem(name: LastFM.Query.method, value: LastFM.Method.userGetTopArtists),
                    URLQueryItem(name: LastFM.Query.user, value: user),
                    URLQueryItem(name: LastFM.Query.period, value: period),
                    URLQueryItem(name: LastFM.Query.limit, value: limit!),
                    URLQueryItem(name: LastFM.Query.apiKey, value: LastFM.apiKey),
                    URLQueryItem(name: LastFM.Query.format, value: LastFM.URLData.format)
                ]
            )
        } else {
            endpoint = Endpoint(
                path: LastFM.URLData.path,
                queryItems: [
                    URLQueryItem(name: LastFM.Query.method, value: LastFM.Method.userGetTopArtists),
                    URLQueryItem(name: LastFM.Query.user, value: user),
                    URLQueryItem(name: LastFM.Query.period, value: period),
                    URLQueryItem(name: LastFM.Query.apiKey, value: LastFM.apiKey),
                    URLQueryItem(name: LastFM.Query.format, value: LastFM.URLData.format)
                ]
            )
        }
        
        return endpoint
    }
    
    static func loveTrack(artist: String,
                          track: String,
                          sessionKey: String,
                          apiSignature: String,
                          love: Bool) -> Endpoint {
        let method = love ? LastFM.Method.trackLove : LastFM.Method.trackUnlove
        return Endpoint(
            path: LastFM.URLData.path,
            queryItems: [
                URLQueryItem(name: LastFM.Query.method, value: method),
                URLQueryItem(name: LastFM.Query.artist, value: artist),
                URLQueryItem(name: LastFM.Query.track, value: track),
                URLQueryItem(name: LastFM.Query.apiKey, value: LastFM.apiKey),
                URLQueryItem(name: LastFM.Query.sessionKey, value: sessionKey),
                URLQueryItem(name: LastFM.Query.apiSignature, value: apiSignature),
                URLQueryItem(name: LastFM.Query.format, value: LastFM.URLData.format)
            ]
        )
    }
    
    static func trackAlbumArt(artist: String,
                              track: String) -> Endpoint {
        return Endpoint(
            path: LastFM.URLData.path,
            queryItems: [
                URLQueryItem(name: LastFM.Query.method, value: LastFM.Method.trackGetInfo),
                URLQueryItem(name: LastFM.Query.apiKey, value: LastFM.apiKey),
                URLQueryItem(name: LastFM.Query.artist, value: artist),
                URLQueryItem(name: LastFM.Query.track, value: track),
                URLQueryItem(name: LastFM.Query.format, value: LastFM.URLData.format)
            ]
        )
    }
}
