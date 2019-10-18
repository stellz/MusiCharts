import UIKit

struct Track {
    
	var title: String = ""
	var artist: String = ""
	var artworkURL: String = ""
	var artworkImage = UIImage(named: "albumArt")
	var artworkLoaded = false
	var isPlaying: Bool = false
    
}
