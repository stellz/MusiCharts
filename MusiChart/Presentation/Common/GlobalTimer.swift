import Foundation

final class GlobalTimer: NSObject {

    //Creates one and only instance of the object using the static keyword for lazy initialization with a closure
    static let sharedTimer: GlobalTimer = {
        let timer = GlobalTimer()
        return timer
    }()
    
    //Declares default initializer to bi private and ensure it is not accessable
    private override init() {}

    var timer: Timer?
    public private(set) var sleepTime = 0.0
    var elapsedTime = 0.0

    // Starts the timer with end time parameter
    func startTimer(withSleepTime minutes: Double) {
        if timer == nil {
            timer?.invalidate()
        }

        //sleep time is in seconds and time is in minutes
        sleepTime = minutes*60

        // We create a NSTimer object and initialize it with given parameters
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }

    // Stops the timer if one is running
    func stopTimer() {
        guard timer != nil else {
            if kDebugLog { print("No timer active, start the timer before you stop it.") }
            return
        }
        timer?.invalidate()
        elapsedTime = 0.0
        sleepTime = 0.0
    }

    // Notification event handler for each 1 second passed
    @objc func timerAction(sender: Any?) {
        if kDebugLog { print("Timer fired.") }

        elapsedTime += 1.0

        // When the given end time elapse we stop the timer and post a notification for that event
        if elapsedTime > sleepTime {
            stopTimer()
            NotificationCenter.default.post(name: Notification.Name(rawValue: TimerNotifications.sleepTimeElapsed), object: nil)
        }
    }
}
