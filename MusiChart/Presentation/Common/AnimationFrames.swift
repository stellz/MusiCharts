import UIKit

class AnimationFrames {

    class func createFrames() -> [UIImage] {

        // Setup "Now Playing" Animation Bars
        var animationFrames = [UIImage]()
        for index in 0...3 {
            if let image = UIImage(named: "NowPlayingBars-\(index)") {
                animationFrames.append(image)
            }
        }

        for index in stride(from: 2, to: 0, by: -1) {
            if let image = UIImage(named: "NowPlayingBars-\(index)") {
                animationFrames.append(image)
            }
        }
        return animationFrames
    }

}
