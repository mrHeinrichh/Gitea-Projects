import Cocoa
import FlutterMacOS
import Sentry

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
    
    override func applicationWillTerminate(_ aNotification: Notification) {
        NotificationCenter.default.removeObserver(self)
      }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let dsn = "http://b7f7132d0aa248b7b8703fc1fd892209@sentry.uutalk.io:9000/9"
        
        SentrySDK.start { options in
            options.dsn = dsn
            options.debug = true
            if let bID = Bundle.main.bundleIdentifier {
                options.environment = bID
            }
            
            options.profilesSampleRate = 0.5
            options.tracesSampleRate = 1.0
            options.debug = false
            options.beforeSend = { event in
                NSLog("registerSentry  \(event)")
                return event
            }
        }
    }
}
