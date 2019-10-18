import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setupCrashlytics()

        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        ThemeManager().applyTheme(to: window)

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
       
        //MPNowPlayingInfoCenter - stop listening for remote control events
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    func setupCrashlytics() {
        
        #if !DEBUG
        Fabric.with([Crashlytics.self])
        #else
        Fabric.sharedSDK().debug = true
        #endif
    }
}
