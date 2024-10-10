import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSApplicationDelegate {
	var previousBadgeNumber = 0
	
	override func awakeFromNib() {
		let flutterViewController = FlutterViewController.init()
        let backgroundView = CustomBackgroundView()

             // Add the background view as a subview of the FlutterViewController's view
        flutterViewController.view.addSubview(backgroundView)

		let windowFrame = self.frame
		self.contentViewController = flutterViewController
		self.setFrame(windowFrame, display: true)
		
		let notificationChannel = FlutterMethodChannel(
			name: "desktopNotification",
			binaryMessenger: flutterViewController.engine.binaryMessenger
		)
		
		let nativeActionChannel = FlutterMethodChannel(
			name: "desktopAction",
			binaryMessenger: flutterViewController.engine.binaryMessenger
		)
        
        let desktopUtilsChannel = FlutterMethodChannel(
            name: "desktopUtilsChannel",
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )
		
		notificationChannel.setMethodCallHandler { [weak self] (call, result) in
			guard let self = self else { return }
			
			switch call.method {
				case "updateBadge":
					if let argument = call.arguments as? [String: Any], let badge = argument["badgeNumber"] as? Int {
						self.updateBadgeNumber(data: badge)
						
					}
				default:
					print("MacOS: No notification function called from Flutter")
			}
		}
		
		nativeActionChannel.setMethodCallHandler { [weak self] (call, result) in
			guard let self = self else { return }
			switch call.method {
				case "openDownloadDir":
					if let argument = call.arguments as? [String: Any], let path = argument["downloadPath"] as? String{
						let fileExist = self.openDownloadDir(data: path)
						result(fileExist)
					}
				case "checkWindowFocus":
					result(self.checkWindowFocus())
				default:
					print("MacOS: No native action function called from Flutter")
			}
		}
        
        desktopUtilsChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
                case "initCompleted":
                    backgroundView.removeFromSuperview()
                default:
                    print("MacOS: No native action function called from Flutter")
            }
        }
		
		RegisterGeneratedPlugins(registry: flutterViewController)
		super.awakeFromNib()
	}
	
	func updateBadgeNumber(data: Int) {
		let dock = NSApplication.shared.dockTile
		if data > 0 {
			dock.badgeLabel = (data >= 999) ? "999+" : "\(data)"
			
//			if data > previousBadgeNumber {
//				NSApplication.shared.requestUserAttention(.informationalRequest)
//			}
		} else {
			dock.badgeLabel = nil
		}
		
		previousBadgeNumber = data
		dock.display()
	}
	
	func openDownloadDir(data: String)-> Bool{
		let fileManager = FileManager.default
		if fileManager.fileExists(atPath: data){
			NSWorkspace.shared.selectFile(data, inFileViewerRootedAtPath: "")
			return true
		}
		else{
			return false
		}
	}
	
	func checkWindowFocus()->Bool{
		return NSApp.isActive && !NSApp.isHidden && !(NSApp.mainWindow?.isMiniaturized ?? false)
	}
	
	override func close(){
		NSApplication.shared.hide(nil)
	}
}

class CustomBackgroundView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        dirtyRect.fill()
        if let image = NSImage(named: "Icon-1024") {
            // Calculate the position to center the image in the view
            let centerX = (dirtyRect.width - 300) / 2
            let centerY = (dirtyRect.height - 300) / 2
            
            // Create a rectangle for the image with a fixed size of 300x300
            let imageRect = CGRect(x: centerX, y: centerY, width: 300, height: 300)
            
            // Draw the image
            image.draw(in: imageRect, from: NSRect.zero, operation: .sourceOver, fraction: 1.0)
        }
        
        super.draw(dirtyRect)
    }
}
