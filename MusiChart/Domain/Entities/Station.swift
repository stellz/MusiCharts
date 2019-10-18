// Class inherits from NSObject so that you may easily add features
// i.e. Saving favorite stations to CoreData, etc

import Foundation

class Station: NSObject, NSCoding {

    var stationName: String
    var stationStreamURL: String
    var stationImageURL: String
    var stationDesc: String
    var stationLongDesc: String

    // MARK: - Initializers
    init(name: String, streamURL: String, imageURL: String, desc: String, longDesc: String) {
        
        self.stationName      = name
        self.stationStreamURL = streamURL
        self.stationImageURL  = imageURL
        self.stationDesc      = desc
        self.stationLongDesc  = longDesc
    }
    
    convenience init(name: String, streamURL: String, imageURL: String, desc: String) {
        
        self.init(name: name, streamURL: streamURL, imageURL: imageURL, desc: desc, longDesc: "")
    }

    // MARK: - Station unarchiving/arhiving from/to data
    
    required init(coder decoder: NSCoder) {
        
        self.stationName = decoder.decodeObject(forKey: "stationName") as? String ?? ""
        self.stationStreamURL = decoder.decodeObject(forKey: "stationStreamURL") as? String ?? ""
        self.stationImageURL = decoder.decodeObject(forKey: "stationImageURL") as? String ?? ""
        self.stationDesc = decoder.decodeObject(forKey: "stationDesc") as? String ?? ""
        self.stationLongDesc = decoder.decodeObject(forKey: "stationLongDesc") as? String ?? ""
    }

    func encode(with coder: NSCoder) {
        
        coder.encode(stationName, forKey: "stationName")
        coder.encode(stationStreamURL, forKey: "stationStreamURL")
        coder.encode(stationImageURL, forKey: "stationImageURL")
        coder.encode(stationDesc, forKey: "stationDesc")
        coder.encode(stationLongDesc, forKey: "stationLongDesc")
    }

    // MARK: - JSON Parsing
    class func parseStation(from stationJSON: [String: Any]) -> Station {
        
        let name      = stationJSON["name"] as? String ?? ""
        let streamURL = stationJSON["streamURL"] as? String ?? ""
        let imageURL  = stationJSON["imageURL"] as? String ?? ""
        let desc      = stationJSON["desc"] as? String ?? ""
        let longDesc  = stationJSON["longDesc"] as? String ?? ""
        
        let station = Station(name: name, streamURL: streamURL, imageURL: imageURL, desc: desc, longDesc: longDesc)
        return station
    }

}
