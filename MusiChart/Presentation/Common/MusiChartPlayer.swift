import MediaPlayer

class MusiChartPlayer: AVPlayer {

    override init() {
        super.init()
        self.rate = 1
    }
}

protocol MusiChartPlayerItemDelegate: class {
    
    func playerItem(playerItem: MusiChartPlayerItem, didUpdateMetadata metaData: [AVMetadataItem]?)
}

class MusiChartPlayerItem: AVPlayerItem {
    
    weak var delegate: MusiChartPlayerItemDelegate?

    init(url URL: URL) {
        
        if kDebugLog { print("MusiChartPlayerItem.init") }
        super.init(asset: AVAsset(url: URL), automaticallyLoadedAssetKeys: [])

        // Add an observer for the metadata change event
        addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.initial, context: nil)
    }

    deinit {
        debugPrint("deinit \(type(of: self))")
        
        // Makes sure that observers are removed before deallocation
        removeObserver(self, forKeyPath: "timedMetadata")
        removeObserver(self, forKeyPath: "status")
    }

    //Handle the metadata change event for the AVPlayerItem (audio track)
    //swiftlint:disable next block_based_kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let avpItem = object as? MusiChartPlayerItem else { return }
        
        switch keyPath {
        case "timedMetadata":
            delegate?.playerItem(playerItem: avpItem, didUpdateMetadata: avpItem.timedMetadata)
        case "status":
            let status = avpItem.status
            
            switch status {
            case .unknown:
                if kDebugLog { print("Unknown audio status") }
            case .readyToPlay:
                if kDebugLog { print("Ready to play. Audio will begin to play now.") }
            case .failed:
                if kDebugLog { print("Audi failed to play") }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: AudioNotifications.audioFailedToPlay), object: nil)
            }
        default:
            break
        }
    }
}
