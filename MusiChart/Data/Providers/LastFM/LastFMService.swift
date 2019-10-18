import Foundation
import CommonCrypto

final class LastFMService: NSObject {
    // MARK: - Login

    // Login to Last.fm
    // The goal of this method is to authenticate with Last.FM and get a session key
    // On success save the sesion key in the keychain. Use the session key to make private api requests
    // The key has lifetime expiry period, so if the user presses Logout we shoud delete the session key from the keychain
    // And obtain new login session with this method
    // For all other requests (scrobble, love, etc.) you should check if there is a session key

    class func login(name: String, password: String, completion: @escaping (_ loginData: LoginData?, _ error: Error?) -> Void) {

        //Build auth.getMobileSession signature, if not correct you will get error 13 message: Invalid Method Signature
        let signatureString = "api_key\(LastFM.apiKey)"
            + "method\(LastFM.Method.authGetMobileSession)"
            + "password\(password)"
            + "username\(name)"
            + "\(LastFM.apiSecret)"
        
        //Hash the signature
        guard let apiSignature = MD5(string: signatureString) else { return }
        
        let endpoint = Endpoint.login(username: name, password: password, apiSignature: apiSignature)
        guard let url = endpoint.url else {
            completion(nil, ResultError.failed("Invalid URL"))
            return
        }

        makeHTTPRequest(url: url, onCompletion: { json, error in
            guard let json = json else {
                if let error = error { print("Http request error: \(error.localizedDescription)") }
                return
            }
            
            let session = json["session"] as? [String: Any]
            
            guard let sessionKey = session?["key"] as? String, let sessionName = session?["name"] as? String else {
                completion(nil, error)
                return
            }
            
            let loginData = (username:sessionName, password: sessionKey)
            
            completion(loginData, error)
        })
    }

    // MARK: - Profile

    class func getUserInfo(userEmail: String, completion: @escaping (_ user: User?, _ error: Error?) -> Void) {
        
        let endpoint = Endpoint.userInfo(user: userEmail)
        guard let url = endpoint.url else {
            completion(nil, ResultError.failed("Invalid URL"))
            return
        }

        makeHTTPRequest(url: url, onCompletion: { json, error in
            guard let json = json else {
                if let error = error { print("Http request error: \(error.localizedDescription)") }
                return
            }
            
            guard let userData = json["user"] as? [String: Any] else {
                completion(nil, error)
                return
            }
            
            let user = User(from: userData)
            completion(user, error)
        })
    }

    // Get user's total playcount
    class func getUserPlaycount(userEmail: String, completion: @escaping (_ playcount: Int?, _ error: Error?) -> Void) {
        
        let endpoint = Endpoint.userInfo(user: userEmail)
        guard let url = endpoint.url else {
            completion(nil, ResultError.failed("Invalid URL"))
            return
        }

        makeHTTPRequest(url: url, onCompletion: { json, error in
            guard let json = json else {
                if let error = error { print("Http request error: \(error.localizedDescription)") }
                return
            }
            
            guard let userData = json["user"] as? [String: Any] else {
                completion(nil, error)
                return
            }
            let user = User(from: userData)
            let playcount = user.plays
            completion(playcount, error)
        })
    }

    // MARK: - Scrobble

    // Scrobble track to Last.fm
    class func scrobbleTrack(song: String, artist: String, sessionKey: String, completion: ((_ jsonData: [String: Any], _ error: Error?) -> Void)?) {
        
        // The timestamp should be in seconds (not in miliseconds *1000) otherwise the track will be ignored by last.fm and won't scrobble
        let timestamp = "\(Date().timeIntervalSince1970)"

        //Build track.scrobble signature, if not correct you will get error 13 message: Invalid Method Signature
        let signatureString = "api_key\(LastFM.apiKey)"
            + "artist\(artist)"
            + "method\(LastFM.Method.trackScrobble)"
            + "sk\(sessionKey)"
            + "timestamp\(timestamp)"
            + "track\(song)"
            + "\(LastFM.apiSecret)"
        
        //Hash the signature
        guard let apiSignature = MD5(string: signatureString) else { return }
        
        let endpoint = Endpoint.scrobbleTrack(artist: artist, track: song, timestamp: timestamp, sessionKey: sessionKey, apiSignature: apiSignature)
        guard let url = endpoint.url else {
            completion?([:], ResultError.failed("Invalid URL"))
            return
        }

        makeHTTPRequest(url: url, onCompletion: { json, error in
            guard let json = json else {
                if let error = error { print("Http request error: \(error.localizedDescription)") }
                return
            }
            completion?(json, error)
        })
    }

    // MARK: - Top Artists
    
    //Period parameter is a String; The default value is "overall" Other values can be: 7day | 1month | 3month | 6month | 12month

    class func getTopArtists(for user: String, period: String = LastFM.Period.overall, limit: Int?, completion: @escaping (_ artists: [Artist], _ error: Error?) -> Void) {
        
        let limitString = limit != nil ? "\(limit!)" : nil

        let endpoint = Endpoint.topArtists(user: user, period: period, limit: limitString)
        guard let url = endpoint.url else {
            completion([], ResultError.failed("Invalid URL"))
            return
        }

        makeHTTPRequest(url: url, onCompletion: { json, error in
            guard let json = json else {
                if let error = error { print("Http request error: \(error.localizedDescription)") }
                return
            }

            guard let topArtistsInfo = json["topartists"] as? [String: Any], let artistInfoArray = topArtistsInfo["artist"] as? [[String: Any]] else { return }
            
            let artists = artistInfoArray.map({ artistInfo in
                return Artist(from: artistInfo)
            })

            completion(artists, error)
        })
    }

    // MARK: - Love Track

    class func loveTrack(love: Bool, song: String, artist: String, sessionKey: String, completion: @escaping (_ jsonData: [String: Any], _ error: Error?) -> Void) {
        
        let methodString = love ? LastFM.Method.trackLove : LastFM.Method.trackUnlove

        //Build track.love signature, if not correct you will get error 13 message: Invalid Method Signature
        let signatureString = "api_key\(LastFM.apiKey)"
            + "artist\(artist)"
            + "method\(methodString)"
            + "sk\(sessionKey)"
            + "track\(song)"
            + "\(LastFM.apiSecret)"
        
        //Hash the signature
        guard let apiSignature = MD5(string: signatureString) else { return }
        
        let endpoint = Endpoint.loveTrack(artist: artist, track: song, sessionKey: sessionKey, apiSignature: apiSignature, love: love)
        guard let url = endpoint.url else {
            completion([:], ResultError.failed("Invalid URL"))
            return
        }

        makeHTTPRequest(url: url, onCompletion: { json, error in
            guard let json = json else {
                if let error = error {
                    print("Http request error: \(error.localizedDescription)")
                }
                return
            }
            completion(json, error)
        })
    }
    
     // MARK: - Album Artwork
     class func getTrackAlbumArt(queryInfo: (String, String), completion: @escaping (_ urlString: String?, _ error: Error?) -> Void) {
        
        let artist = queryInfo.0
        let track = queryInfo.1
        
        let endpoint = Endpoint.trackAlbumArt(artist: artist, track: track)
        guard let url = endpoint.url else {
            completion(nil, ResultError.failed("Invalid URL"))
            return
        }
        
        makeHTTPRequest(url: url) { (json, error) in
            guard let json = json else {
                completion(nil, error)
                return
            }
            
            if error != nil {
                completion(nil, error)
            } else {
                // Get Largest Sized LastFM Image
                guard let trackArray = json["track"] as? [String: Any],
                    let albumArray = trackArray["album"] as? [String: Any],
                    let imageArray = albumArray["image"] as? [Any] else {
                        completion(nil, error)
                        return
                }
                
                let index = imageArray.count - 1
                guard imageArray.indices.contains(index) else {
                    completion(nil, error)
                    return
                }
                let lastImage = imageArray[index] as? [String: Any]
                guard let artURL = lastImage?["#text"] as? String, artURL.range(of: "/noimage/") == nil else {
                    completion(nil, error)
                    return
                }
                completion(artURL, nil)
            }
        }
    }
    
    // MARK: - -------------------------------------

    class func makeHTTPRequest(url: URL, onCompletion: @escaping ServiceResponse) {

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request, completionHandler: { responseData, _, error -> Void in
            
            guard let responseData = responseData else {
                onCompletion(nil, error)
                return
            }
            
            do {
                if kDebugLog { print("JSON String: \(String(describing: String(data: responseData, encoding: .utf8)))") }
                let jsonData = try JSONSerialization.jsonObject(with: responseData, options: [])
                guard let jsonDictionary = jsonData as? [String: Any] else {
                        return
                }
                onCompletion(jsonDictionary, error)
            } catch let parsingError {
                print("Parsing Error: \(parsingError)")
                onCompletion(nil, parsingError)
            }
            
        })
        task.resume()
    }

    class func MD5(string: String) -> String? {
        guard let messageData = string.data(using: String.Encoding.utf8) else { return nil }
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))

        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }

        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}
